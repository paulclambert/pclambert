*! version 0.1 2026-09-22
//--------- sessions.ado (begin) ------------------------------------------------
program sessions
    version 18
    
    gettoken subcmd options : 0, parse(", ")

    // clear sessions
    if inlist("`subcmd'","clear","monitor") {
      // check if any sessions running
      capture java, shared(sessions): Sessions.AnyActiveSessions()
      if "`anyactive'" == "1" {
        display as error "You have active sessions. Kill these sessions first."
        exit 198
      }
      
      java, shared(sessions): /reset
      capture program drop _sessions
      if "`subcmd'" == "clear" exit
    }         

    // main work done in _sessions.ado
    _sessions `subcmd' `options'
end
//--------- sessions.ado (end) --------------------------------------------------
