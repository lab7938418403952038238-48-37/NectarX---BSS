/************************************************************************
 * PineSnake.ahk
 * Custom Natro Macro field pattern for the upper-left / underneath
 * the large Pine Tree area in Pine Tree Forest.
 *
 * Pattern author: Custom pattern drafted with ChatGPT
 *
 * HOW NATRO RUNS THIS:
 * - Natro supplies the globals: size, reps, FwdKey, BackKey,
 *   LeftKey, RightKey, and the nm_Walk() helper.
 * - size is set by Natro from the Pattern Size dropdown.
 * - reps is set by Natro from the Pattern Reps / width setting.
 * - Natro starts/restarts pattern cycles while gathering and checks
 *   backpack/time limits outside this file. Do NOT add an endless loop.
 *
 * NATRO SIZE MULTIPLIERS (verified from NatroMacro nm_gather):
 *   XS = 0.25x   S = 0.50x   M = 1.00x   L = 1.50x   XL = 2.00x
 *
 * Each movement below is multiplied by Natro's size variable.
 * Example: "DOWN 5" becomes 1.25 tiles at XS, 2.5 at S,
 * 5 at M, 7.5 at L, and 10 at XL.
 *
 * nm_Walk() uses Natro's Walk() movement routine. This means movement
 * timing is handled by Natro's walking system rather than fixed Sleep()
 * delays or manually timed key holds. It does not use visual position
 * tracking or guarantee that game lag / terrain / collisions cannot
 * cause drift.
 *
 * ROUTE (one complete cycle):
 *   DOWN 5, RIGHT 1, UP 5, RIGHT 1, DOWN 5,
 *   RIGHT 1, UP 5, RIGHT 1, DOWN 5, LEFT 4,
 *   UP 12, RIGHT 12, LEFT 5, DOWN 7
 *
 * The full route is repeated "reps" times each time Natro runs this
 * pattern cycle. Natro then controls the next cycle and bag/time checks.
 *
 * NET MOVEMENT PER CYCLE AT ANY SIZE:
 *   Horizontal: 7 units RIGHT (scaled by size)
 *   Vertical:   0 units net
 *
 * Start at the intended upper-left / large Pine Tree gathering position.
 * Test XS with reps = 1 first. No Supreme Saturator is required by this
 * pattern. Sprinkler placement is controlled separately in Natro.
 ************************************************************************/

Loop reps
{
    ; --- Initial snake section ---
    nm_Walk(5 * size, BackKey)   ; Down 5
    nm_Walk(1 * size, RightKey)  ; Right 1

    nm_Walk(5 * size, FwdKey)    ; Up 5
    nm_Walk(1 * size, RightKey)  ; Right 1

    nm_Walk(5 * size, BackKey)   ; Down 5
    nm_Walk(1 * size, RightKey)  ; Right 1

    nm_Walk(5 * size, FwdKey)    ; Up 5
    nm_Walk(1 * size, RightKey)  ; Right 1

    nm_Walk(5 * size, BackKey)   ; Down 5
    nm_Walk(4 * size, LeftKey)   ; Left 4

    ; --- Continuation section (also repeats every cycle) ---
    nm_Walk(12 * size, FwdKey)   ; Up 12
    nm_Walk(12 * size, RightKey) ; Right 12
    nm_Walk(5 * size, LeftKey)   ; Left 5
    nm_Walk(7 * size, BackKey)   ; Down 7
}
