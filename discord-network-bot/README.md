# NectarX Network — Discord Bot (Natro + Revolution)

A starter bot that watches channels where Natro Macro and Revolution post their Discord webhook reports, stores the latest parsed report per account, and offers slash commands for a combined view.

## Important webhook limitation

A Discord webhook URL is an **outgoing-only posting URL**. A bot cannot use that URL to read the data sent through it. This starter bot instead reads the resulting messages/embeds in Discord channels it can access. Revolution documents hourly reports and webhook/bot modes in its [Discord setup guide](https://revolutionmacro.com/docs/settings/discord-webhook-and-bot/). Natro also supports Discord status reporting in its settings.

The parser is deliberately best-effort: macro embed formats can vary by version, and some reports may be images/graphs rather than text fields. If a value is not present as text, it will show as “Not provided.” Do not assume every statistic can be extracted from a chart image.

## Features

- `/farmers` — combined active/stale account list
- `/report account:<name>` — latest report for an account
- `/setrole account:<name> role:<Main|Alt>` — label an account
- `/linkalt account:<name>` — associate an account with the invoking Discord user
- `/field field_name:<field>` — recent farmers by field
- `/leaderboard` — rank parsed numeric honey/hour values
- Optional periodic combined summary to a channel
- Local JSON persistence in `data/reports.json`

## Setup

1. Create an app/bot at the [Discord Developer Portal](https://discord.com/developers/applications).
2. Under **Bot**, enable **Message Content Intent**. Invite it with `bot` and `applications.commands` scopes and permissions: View Channels, Read Message History, Send Messages, Embed Links.
3. Add the bot to your server and ensure it can view the channels where the macro webhooks post.
4. Copy `.env.example` to `.env`, fill in `DISCORD_TOKEN`, and optionally configure channel IDs.
5. Install Python 3.10+ and run:

   ```bash
   python -m venv .venv
   # Windows:
   .venv\\Scripts\\activate
   # macOS/Linux:
   source .venv/bin/activate
   pip install -r requirements.txt
   python bot.py
   ```

6. In both macro settings, configure their Discord webhooks to post into channels the bot can read. You can use separate channels and set `REPORT_CHANNEL_IDS` to those channel IDs, or leave it blank to watch all accessible channels.
7. Test with a fresh report, then run `/farmers`.

## Environment

- `DISCORD_TOKEN`: bot token (secret; never commit it)
- `REPORT_CHANNEL_IDS`: optional comma-separated channel IDs to monitor
- `SUMMARY_CHANNEL_ID`: optional channel to receive combined summaries
- `SUMMARY_INTERVAL_MINUTES`: summary frequency (minimum 5)
- `ONLINE_TTL_MINUTES`: how long a report is considered fresh

## Security and limitations

- Never commit `.env`, webhook URLs, or bot tokens. If exposed, rotate them.
- Use private report channels. The bot needs message access only to those channels.
- Main/alt linking is self-claimed by Discord user; it is not proof of Roblox account ownership.
- This bot does not join Roblox servers or control macro sessions.
- It does not currently parse chart images with OCR. Exact honey/hour extraction depends on the text included in the macro embed.
- Test parser compatibility with real Natro and Revolution report examples before relying on rankings.
