"""NectarX Network Discord bot: aggregates Natro and Revolution webhook posts.

Important: Discord webhook URLs are write-only. This bot reads messages posted into
channels it can access; it does not read a webhook URL directly. Keep macro webhook
channels private and never publish webhook URLs or bot tokens.
"""
from __future__ import annotations

import json
import os
import re
import time
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

import discord
from discord import app_commands
from discord.ext import commands, tasks
from dotenv import load_dotenv

load_dotenv()
TOKEN = os.getenv("DISCORD_TOKEN", "").strip()
REPORT_CHANNEL_IDS = {
    int(x.strip()) for x in os.getenv("REPORT_CHANNEL_IDS", "").split(",")
    if x.strip().isdigit()
}
SUMMARY_CHANNEL_ID = int(os.getenv("SUMMARY_CHANNEL_ID", "0") or "0")
SUMMARY_INTERVAL_MINUTES = max(5, int(os.getenv("SUMMARY_INTERVAL_MINUTES", "60") or "60"))
ONLINE_TTL_MINUTES = max(10, int(os.getenv("ONLINE_TTL_MINUTES", "90") or "90"))
DATA_FILE = Path("data/reports.json")
DATA_FILE.parent.mkdir(parents=True, exist_ok=True)

intents = discord.Intents.default()
intents.message_content = True
intents.guilds = True
intents.messages = True
bot = commands.Bot(command_prefix="!", intents=intents)

# Records are keyed by (guild_id, normalized account name).
records: dict[str, dict] = {}
owners: dict[str, dict] = {}
fields: dict[str, str] = {}

def load_data():
    global records, owners, fields
    if DATA_FILE.exists():
        try:
            raw = json.loads(DATA_FILE.read_text(encoding="utf-8"))
            records = raw.get("records", {})
            owners = raw.get("owners", {})
            fields = raw.get("fields", {})
        except (OSError, json.JSONDecodeError):
            print("Warning: report database could not be read; starting with empty data.")

def save_data():
    DATA_FILE.write_text(json.dumps({
        "records": records, "owners": owners, "fields": fields
    }, indent=2), encoding="utf-8")

def key_for(guild_id: int, account: str) -> str:
    return f"{guild_id}:{account.casefold().strip()}"

def parse_number(text: str | None) -> float | None:
    if not text:
        return None
    s = text.strip().replace(",", "").replace("$", "").replace(" ", "")
    m = re.search(r"(-?\d+(?:\.\d+)?)\s*([kmbtq])?", s, re.I)
    if not m:
        return None
    n = float(m.group(1))
    suffix = (m.group(2) or "").lower()
    return n * {"k":1e3,"m":1e6,"b":1e9,"t":1e12,"q":1e15}.get(suffix, 1)

def fields_from_message(message: discord.Message) -> dict[str, str]:
    values: dict[str, str] = {}
    for embed in message.embeds:
        if embed.title:
            values["title"] = embed.title
        if embed.description:
            values["description"] = embed.description
        for field in embed.fields:
            values[field.name.strip().lower()] = field.value.strip()
        if embed.author and embed.author.name:
            values["author"] = embed.author.name
        if embed.footer and embed.footer.text:
            values["footer"] = embed.footer.text
    if message.content:
        values["content"] = message.content
    return values

def pick(values: dict[str, str], *terms: str) -> str | None:
    for name, value in values.items():
        if any(term in name.lower() for term in terms):
            return value
    joined = "\n".join(values.values())
    for term in terms:
        m = re.search(rf"{re.escape(term)}\s*[:：-]\s*([^\n|]+)", joined, re.I)
        if m:
            return m.group(1).strip()
    return None

def parse_report(message: discord.Message) -> dict | None:
    values = fields_from_message(message)
    text = " ".join([*values.keys(), *values.values()]).lower()
    if not any(word in text for word in ("natro", "revolution", "hourly report", "honey/hour", "honey per hour")):
        return None

    source = "Revolution" if "revolution" in text else ("Natro" if "natro" in text else "Unknown")
    account = pick(values, "account", "player", "username", "profile") or (
        message.author.display_name if message.webhook_id else message.author.name
    )
    field = pick(values, "current field", "field", "gather field") or "Unknown"
    honey_per_hour_raw = pick(values, "honey / hour", "honey/hour", "honey per hour", "hourly honey", "honey rate")
    total_honey_raw = pick(values, "total honey", "honey made", "honey collected", "total")
    honey_per_hour = parse_number(honey_per_hour_raw)
    total_honey = parse_number(total_honey_raw)
    status = pick(values, "status", "state") or ("Running" if "running" in text or "starting" in text else "Reported")
    return {
        "guild_id": message.guild.id if message.guild else 0,
        "account": account[:80], "macro": source, "field": field[:80],
        "honey_per_hour": honey_per_hour, "honey_per_hour_raw": honey_per_hour_raw,
        "total_honey": total_honey, "total_honey_raw": total_honey_raw,
        "status": status[:60], "updated_at": datetime.now(timezone.utc).isoformat(),
        "message_url": message.jump_url, "channel_id": message.channel.id,
    }

def fresh(rec: dict) -> bool:
    try:
        updated = datetime.fromisoformat(rec["updated_at"])
        return (datetime.now(timezone.utc) - updated).total_seconds() < ONLINE_TTL_MINUTES * 60
    except (KeyError, ValueError, TypeError):
        return False

def format_num(n: float | None, raw: str | None = None) -> str:
    if n is None:
        return raw or "Not provided"
    for divisor, suffix in ((1e15,"Q"),(1e12,"T"),(1e9,"B"),(1e6,"M"),(1e3,"K")):
        if abs(n) >= divisor:
            return f"{n/divisor:.2f}{suffix}"
    return f"{n:,.0f}"

def build_report_embed(guild_id: int) -> discord.Embed:
    rows = [r for k,r in records.items() if k.startswith(f"{guild_id}:")]
    rows.sort(key=lambda r: (not fresh(r), -(r.get("honey_per_hour") or 0)))
    embed = discord.Embed(title="🐝 NectarX Network — Active Farmers",
        description=f"Reports are parsed from Natro and Revolution posts. Online window: {ONLINE_TTL_MINUTES} min.",
        colour=discord.Colour.gold(), timestamp=datetime.now(timezone.utc))
    if not rows:
        embed.description = "No reports detected yet. Check channel access and post a macro report."
        return embed
    for r in rows[:20]:
        status = "🟢 Online" if fresh(r) else "⚫ Stale"
        embed.add_field(
            name=f"{status} · {r['account']} ({r['macro']})",
            value=f"**Field:** {r['field']}\n**Honey/hour:** {format_num(r.get('honey_per_hour'), r.get('honey_per_hour_raw'))}\n**Total:** {format_num(r.get('total_honey'), r.get('total_honey_raw'))}\n**Status:** {r['status']}",
            inline=True)
    embed.set_footer(text="Parsed fields depend on the macro's webhook embed format.")
    return embed

@bot.event
async def on_ready():
    load_data()
    try:
        synced = await bot.tree.sync()
        print(f"Synced {len(synced)} slash commands.")
    except Exception as exc:
        print(f"Slash-command sync failed: {exc}")
    if not hourly_summary.is_running():
        hourly_summary.start()
    print(f"NectarX Network connected as {bot.user}")

@bot.event
async def on_message(message: discord.Message):
    if message.author.bot and not message.webhook_id:
        await bot.process_commands(message)
        return
    if not message.guild:
        return
    if REPORT_CHANNEL_IDS and message.channel.id not in REPORT_CHANNEL_IDS:
        return
    report = parse_report(message)
    if report:
        key = key_for(report["guild_id"], report["account"])
        previous = records.get(key, {})
        # Preserve manually assigned main/alt role and owner across report updates.
        report["role"] = previous.get("role", "Unassigned")
        report["owner_id"] = previous.get("owner_id")
        records[key] = report
        save_data()
    await bot.process_commands(message)

@bot.tree.command(name="farmers", description="Show the latest Natro and Revolution farming reports")
async def farmers(interaction: discord.Interaction):
    await interaction.response.send_message(embed=build_report_embed(interaction.guild_id or 0), ephemeral=False)

@bot.tree.command(name="report", description="Show the latest report for an account")
@app_commands.describe(account="Account/profile name")
async def report_cmd(interaction: discord.Interaction, account: str):
    rec = records.get(key_for(interaction.guild_id or 0, account))
    if not rec:
        await interaction.response.send_message(f"No report found for **{account}** yet.", ephemeral=True)
        return
    embed = discord.Embed(title=f"📊 {rec['account']} — {rec['macro']}", colour=discord.Colour.blurple())
    embed.add_field(name="Field", value=rec["field"], inline=True)
    embed.add_field(name="Honey/hour", value=format_num(rec.get("honey_per_hour"), rec.get("honey_per_hour_raw")), inline=True)
    embed.add_field(name="Total honey", value=format_num(rec.get("total_honey"), rec.get("total_honey_raw")), inline=True)
    embed.add_field(name="Status", value=rec["status"], inline=True)
    embed.add_field(name="Main/Alt", value=rec.get("role", "Unassigned"), inline=True)
    embed.add_field(name="Last update", value=rec["updated_at"], inline=False)
    if rec.get("message_url"):
        embed.url = rec["message_url"]
    await interaction.response.send_message(embed=embed, ephemeral=True)

@bot.tree.command(name="setrole", description="Set a reported account as Main or Alt")
@app_commands.describe(account="Account/profile name", role="Main or Alt")
@app_commands.choices(role=[
    app_commands.Choice(name="Main", value="Main"),
    app_commands.Choice(name="Alt", value="Alt"),
])
async def setrole(interaction: discord.Interaction, account: str, role: app_commands.Choice[str]):
    key = key_for(interaction.guild_id or 0, account)
    rec = records.get(key)
    if not rec:
        await interaction.response.send_message("No report found for that account name yet.", ephemeral=True)
        return
    rec["role"] = role.value
    save_data()
    await interaction.response.send_message(f"Set **{rec['account']}** to **{role.value}**.", ephemeral=True)

@bot.tree.command(name="linkalt", description="Link an alt account to your Discord profile")
@app_commands.describe(account="Exact account/profile name from a macro report")
async def linkalt(interaction: discord.Interaction, account: str):
    key = key_for(interaction.guild_id or 0, account)
    rec = records.get(key)
    if not rec:
        await interaction.response.send_message("No report found for that account name yet. Start the macro and try again.", ephemeral=True)
        return
    # Account ownership is opt-in and based on the invoking Discord user.
    rec["owner_id"] = interaction.user.id
    rec["role"] = "Alt"
    save_data()
    await interaction.response.send_message(f"Linked **{rec['account']}** as an alt under your Discord profile. Use /setrole to change its label.", ephemeral=True)

@bot.tree.command(name="field", description="Show which reported accounts are farming a field")
@app_commands.describe(field_name="Field name, e.g. Pine Tree")
async def field_cmd(interaction: discord.Interaction, field_name: str):
    matches = [r for k,r in records.items() if k.startswith(f"{interaction.guild_id or 0}:") and field_name.casefold() in r["field"].casefold() and fresh(r)]
    if not matches:
        await interaction.response.send_message(f"No recent reports found for **{field_name}**.", ephemeral=True)
        return
    lines = [f"• **{r['account']}** — {r['macro']} — {format_num(r.get('honey_per_hour'), r.get('honey_per_hour_raw'))}/h" for r in matches[:25]]
    await interaction.response.send_message(f"🌼 **Farmers in {field_name}:**\n" + "\n".join(lines))

@bot.tree.command(name="leaderboard", description="Rank reported accounts by honey per hour")
async def leaderboard(interaction: discord.Interaction):
    rows = [r for k,r in records.items() if k.startswith(f"{interaction.guild_id or 0}:") and r.get("honey_per_hour") is not None]
    rows.sort(key=lambda r: r["honey_per_hour"], reverse=True)
    lines = [f"**{i}. {r['account']}** · {r['macro']} · {format_num(r['honey_per_hour'])}/h" for i,r in enumerate(rows[:10], 1)]
    await interaction.response.send_message("🏆 **Honey/hour leaderboard**\n" + ("\n".join(lines) if lines else "No numeric hourly reports parsed yet."))

@tasks.loop(minutes=SUMMARY_INTERVAL_MINUTES)
async def hourly_summary():
    if not SUMMARY_CHANNEL_ID:
        return
    channel = bot.get_channel(SUMMARY_CHANNEL_ID)
    if isinstance(channel, discord.TextChannel):
        try:
            await channel.send(embed=build_report_embed(channel.guild.id))
        except discord.Forbidden:
            print("Missing permission to post summary.")

@hourly_summary.before_loop
async def before_hourly_summary():
    await bot.wait_until_ready()

if not TOKEN:
    raise SystemExit("Missing DISCORD_TOKEN. Copy .env.example to .env and add your bot token.")
load_data()
bot.run(TOKEN)
