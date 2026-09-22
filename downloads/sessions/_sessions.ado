*! version 0.1 2026-09-22
//--------- _sessions.ado (begin) ------------------------------------------------
program _sessions
    version 18
  
    gettoken subcmd options : 0, parse(", ")
    
    if "`subcmd'" == "init" {                    // initialization
      sessions_init `options'
      exit
    }    
    
    if "`subcmd'" == "start" {                   // start new session
      sessions_start `options'
      exit
    }

    if "`subcmd'" == "kill" {                    // kill sessions(s)
      sessions_kill `options'
      exit
    }    
    
    if "`subcmd'" == "list" {                    // list sessions
      sessions_list `options'
      exit
    }        

    if "`subcmd'" == "resources" {               // shows resources
      sessions_resources `options'
      exit
    }        
    
    if "`subcmd'" == "wait_for_resources" {      // wait for resources
      sessions_wait_for_resources `options'
      exit
    }      
    
    if "`subcmd'" == "monitor" {                // live monitoring
      sessions_monitor `options'
      exit
    }       

    di as error "Unknown sessions subcommand `subcmd'"
    exit 198
end

// -----sessions_init (begin)------
program define sessions_init
  syntax, [STATAexe(string)]


  global sessions_STATAEXE `stataexe'
  
  // check Stata exe file
  if "${sessions_STATAEXE}" == "" {
    sessions_get_stataexe
    global sessions_STATAEXE `r(StataExe)'
  }

  global sessions_STATAEXE = subinstr("${sessions_STATAEXE}","\","/",.)
 
  confirm file "${sessions_STATAEXE}"
  
  // Initialization
  qui java, shared(sessions): Macro.setLocal("initialized",""+Initialized)
  if `initialized' {
    di as error "sessions is already initialized."
    di as error "use -sessions clear- first if you want a new instance of sessions."
    exit 198
  }
  
  qui java, shared(sessions): int Initialized = 1
  di as result "--sessions is initialized--"
  di "Stata executable: ${sessions_STATAEXE}"
  di as result "Available resources:"
  sessions_resources
end
// -----sessions_init (end)------

// -----sessions_start (begin)------
program define sessions_start
  syntax anything(name=dofile_and_args), [name(string) icon frommonitor]
  tokenize `"`dofile_and_args'"'
  local dofile `1'
  local j 2

  // if called from sessions monitor arguments passed separately
  if "`frommonitor'" == "" {
    local Narguments = 0
    local a 1
    while "``j''" != "" {
      local arg`a' `"``j''""'
      local ++a
      local Narguments = `Narguments' + 1
      mac shift 1
    }
  }

  confirm file `"`dofile'"'
  qui java, shared(sessions) : Macro.setLocal("sessionid","" + (SessionList.size() +1 )) 
  if "`name'" == "" local name "Session `sessionid'"
  java, shared(sessions) : Sessions.startsession("`dofile'")
end
// -----sessions_start (end)------

// -----sessions_kill (begin)------
program define sessions_kill
  syntax anything(name=id)
  capture confirm number `id'
  if _rc {
    if "`id'" != "_all" {
      di as error "Illegal id number"
      exit 198
    }
    java, shared(sessions) : Sessions.killallsessions("`id'")
    exit
  }
  java, shared(sessions) : Sessions.killsession(`id')
end
// -----sessions_kill (end)------

// -----sessions_list (begin)------
program define sessions_list
  java, shared(sessions) : Sessions.list_sessions()
end
// -----sessions_list (end)------

// -----sessions_resources (begin)------
program define sessions_resources, rclass
  java, shared(sessions) : Sessions.resources()
  di as result "  Logical Processors: " %2.0f `Nprocessors' " | CPU Load:" %2.0f `cpuload' "% | Free memory: " %2.0f `free_mem' "%"
  return scalar cpuload     = `cpuload'
  return scalar free_memory = `free_mem'
  return scalar Ncpus = `Nprocessors'
  java, shared(sessions): Sessions.NActiveSessions()
  di as result "  You have `Nactive' active sessions (excluding this one)."
  return scalar active_sessions = `Nactive'
end
// -----sessionsresources (end)------

// -----sessions_wait_for_resources (begin)------
program define sessions_wait_for_resources 
  syntax, [WAITTime(integer 10) cpuload(integer 75) FREEMEMory(integer 25) display ///
           MAXSessions(integer 10)]
  local waittime = `waittime'*1000
  while 1 {
    sessions_resources
    local obs_cpuload `r(cpuload)'
    local obs_freememory `r(free_memory)'
    java, shared(sessions) : Sessions.NActiveSessions()
    if "`display'" != "" {
      di as result "CPU load: " %2.0f `obs_cpuload' "%, Free memory: " %2.0f `obs_freememory' "%"
      sessions_list
      di ""
    }
    if (`obs_freememory'<`freememory' | `obs_cpuload'>`cpuload' | `Nactive'>=`maxsessions') {
      sleep `waittime'
      continue
    }
    else continue, break
  }
end
// -----sessions_wait_for_resources (end)------

// -----sessions_monitor (start)------
program define sessions_monitor
  syntax [if][in],                 DOFiles(string)                                        ///
                                   NAMEs(string)                                          ///
                                   [                                                      ///
                                   ARGuments(varlist)                                     ///
                                   COMMONdo(string asis)                                  ///
                                   COMPRESS                                               ///
                                   CPUload(integer 75)                                    ///
                                   DETAIL                                                 ///
                                   FREEMEMory(integer 25)                                 ///
                                   GRAPHICSON                                             ///
                                   LOGDELETE                                              ///
                                   MAXSessions(integer 10)                                ///
                                   STARTGap(integer 1)                                    ///
                                   STARTPath(string)                                      ///
                                   UPDATEtime(integer 5)                                  ///
                                   WAITVAR(varname)                                       ///
                                   ]
// add error checks  
  marksample touse  
  local startgap = `startgap'*1000

  tempname monitorframe
  frame put `dofiles' `names' `arguments' `waitvar' if `touse', into(`monitorframe')
  frame `monitorframe' {
    qui gen PID = .z
    qui gen starttime = ""
    qui gen stoptime  = ""
    qui count if `names' == "_wait_"
    local Nwaits `r(N)'
    if `Nwaits'>0 & "`waitvar'" != "" {
      di as error "You can't specify both a wait variable and use _wait_"
      exit 198
    }
    qui count if `names' == "_wait_" & `dofiles' != ""
    if `r(N)' {
      di as error "The dofile name should be an empty string in a row which contains _wait_ for the Session name"
      exit 198
    }

    if `Nwaits'>0 {
       gen wait = 0
       qui replace wait = 1 if `names'[_n-1] == "_wait_"
       qui drop if `names' == "_wait_"
       local waitvar wait
    }
    tempvar tmpID
    qui gen `tmpID'   = _n 

    qui replace `tmpID' = `tmpID'[_n-1] if `names'==`names'[_n-1]  & !missing(`names'[_n-1])
    qui egen ID = group(`tmpID')

    gen row = _n
    if "`waitvar'" != "" {
      tempvar waitvarall
      qui bysort ID (row): egen `waitvarall' = max(`waitvar')
      qui replace  `waitvar' = `waitvarall'
      drop `waitvarall'
    }

    qui bysort ID (row): gen Nsessiondofiles = _N if _n==1
    qui bysort ID (row): gen firstrow = _n==1
    qui bysort ID (row): gen lastrow  = _n==_N

    qui gen status    = "Queued" if lastrow

    if "`names'" == "" {
      qui gen names = "Session " + strofreal(ID)
      local names names
    }
    quietly count if firstrow
    local TotalSessions = r(N)
    qui gen lognames = ""

    if "`waitvar'" != "" {
      qui replace status = status + "(W)" if `waitvar' & lastrow
    }
    order ID PID
  }
  if "`detail'" == "" {
    local monitorframe_list ID `names' PID status starttime stoptime 
  }
  else {
    local monitorframe_list ID `names' PID `dofiles' status starttime stoptime 
  }

  // create/tidy folders 
  sessions_create_tidy_folders, `logdelete'
  
  local wait 0
  local i 1 

  local updatetime_start = tc(`c(current_date)' `c(current_time)') / 1000
  sessions_monitor_listframe, starttime(`updatetime_start') frame(`monitorframe')  ///
                                 list(`monitorframe_list') updatetime(-1) `detail' ///
                                  `compress'
  while 1 {
    qui sessions_resources
    local obs_cpuload `r(cpuload)'
    local obs_freememory `r(free_memory)'
    java, shared(sessions) : Sessions.NActiveSessions()
    java, shared(sessions) : Sessions.Nsessions()
    if `Nsessions'>0 sessions_check_finished, frame(`monitorframe') 
    
    if `wait' { // separate program???
      frame `monitorframe' {
        qui count if inlist(status,"Completed","ERROR") & lastrow & ID<`i'
        if `r(N)' == `=`i'-1' {
          //qui replace status = "Completed" if ID==`i' & lastrow
          //qui replace stoptime = subinstr("${S_DATE}"," ","",.) + ": " + substr("$S_TIME", 1, 5) if ID==`i' & lastrow
          if "`waitvar'" != "" qui replace `waitvar' = 0 if ID==`i' & firstrow
          local wait 0
        }
      }
    }
    
    // check if completed, no available resources or start a new session.
    frame `monitorframe': qui count if inlist(status,"Completed","ERROR") & lastrow
    if `r(N)' == `TotalSessions' {
      di _newline _newline "{bf: All sessions completed at ${S_DATE}: ${S_TIME}}"
      local listif = cond("`detail'"=="","if lastrow","")
      sessions_monitor_listframe, starttime(`updatetime_start') frame(`monitorframe') ///
                                  list(`monitorframe_list') updatetime(-1) `detail'   ///
                                  `compress'    
      frame `monitorframe': qui count if status == "ERROR" & lastrow
      if `r(N)' {
        di as error "At least one session exited with an error code."
        di as error "The log files where errors occurred are listed below."
        forvalues s=1/`Nsessions' {
          frame `monitorframe': qui levelsof row if ID == `s' & lastrow, local(rownum)
          frame `monitorframe': local status_s = status[`rownum'] 
          if "`status_s'" == "ERROR" {
            frame `monitorframe': local logfile = lognames[`rownum']
            display as smcl `"   {view "`logfile'"}"'
          }
        }
      }
      continue, break
    }
    else if (`obs_freememory'<`freememory' | `obs_cpuload'>`cpuload' | ///
             `Nactive'>=`maxsessions' /*| `i'> `TotalSessions'*/              | ///
             `wait') {
      sessions_monitor_listframe, starttime(`updatetime_start') frame(`monitorframe') ///
                                 list(`monitorframe_list') updatetime(`updatetime') `detail' ///
                                 `compress'
      sleep `startgap'
      continue    
    }
    else {
      if `i'> `TotalSessions' continue
      java, shared(sessions) : Sessions.Nsessions()
      local session_number = `Nsessions' + 1
      
      local nextdofile _sessionsdo/sessions`session_number'.do
       
      frame `monitorframe' {
        qui levelsof row if ID==`i' & firstrow, local(waitrow)
        if "`waitvar'" != "" local currentwaitval `=`waitvar'[`waitrow']' 
        else local currentwaitval 0
      }
      if `currentwaitval' {
        frame `monitorframe': qui replace status = "Waiting" if ID == `i' & lastrow
        if "`waitvar'" == "" {
          frame `monitorframe': qui replace starttime = subinstr("${S_DATE}"," ","",.) + ": " + substr("$S_TIME", 1, 8) if ID==`i' & lastrow
        }
        local wait 1
        continue
      }
      local startpathopt startpath(`startpath')
      sessions_create_session_do,   session(`session_number') dofiles(`dofiles')   ///
                                    arguments(`arguments') commondo(`commondo')  ///
                                    frame(`monitorframe') `graphicson' `startpathopt'
      frame `monitorframe': qui replace lognames = "`r(logname)'" if ID==`i' & lastrow

      sessions_start "`startpath'/`nextdofile'",  frommonitor
      java, shared(sessions): Sessions.Getpid(`session_number')
      frame `monitorframe' {
        qui replace PID = `pid' if ID == `i' & lastrow
        qui replace status = "Active" if ID == `i' & lastrow
        qui replace status = "" if ID == `i' & !lastrow & Nsessiondofiles>1

        qui replace starttime = subinstr("${S_DATE}"," ","",.) + ": " +  ///
                                substr("$S_TIME", 1, 8)                  ///
                                if ID==`i' & lastrow
        sessions_monitor_listframe, starttime(`updatetime_start')     ///
                                     frame(`monitorframe')             ///
                                     list(`monitorframe_list')         ///
                                     updatetime(`updatetime') `detail'  ///
                                     `compress'   
      }
      local ++i
      sleep `startgap'
    }
  }                   
end                        
// -----sessions_monitor (end)------


// -----sessions_monitor_list (start)------
program define sessions_monitor_listframe
  syntax , starttime(string) frame(string) list(string) updatetime(string) [detail compress]
  local now = tc(`c(current_date)' `c(current_time)') / 1000
  if (`now' - `starttime')>`updatetime' {
    di _newline _newline "Update at ${S_DATE}: ${S_TIME}"
    sessions_resources
    local listif = cond("`detail'"=="","if lastrow","")
    local separate = cond("`compress'"=="","sepby(ID)","separator(0)") 
    frame `frame': list `list' `listif', noobs `separate' divider abbrev(20)  nodotz 
    c_local updatetime_start `now'
  }
end
// -----sessions_monitor_list (end)------

// -----sessions_check_finished (start)------
program define sessions_check_finished
  syntax , frame(string) /*Nsessions(string)*/
  frame `frame' {    
    java, shared(sessions): Sessions.Nsessions()
    forvalues i = 1/`Nsessions' {
      qui levelsof row if ID==`i' & lastrow, local(rownum)
      if status[`rownum']=="Active" {
        java, shared(sessions): Sessions.CheckActiveSession(`=ID[`rownum']')
        if !`active' {
          local logfile = lognames[`rownum']
          mata: st_local("session_failed",strofreal(find_regex_in_file("`logfile'","r\(([0-9]+)\)")))
          qui replace status = cond(`session_failed',"ERROR","Completed") if ID==`i' & lastrow
          qui replace stoptime = subinstr("${S_DATE}"," ","",.) + ": " + substr("$S_TIME", 1, 8) if ID==`i' & lastrow
          capture erase sessions`i'.log
        }
      }
    }
  }
end
// -----sessions_check_finished (end)------

// -----sessions_create_sessions_do (start)------
program define sessions_create_session_do, rclass
  syntax, session(string) dofiles(string) arguments(string)     ///
          commondo(string asis) frame(string) [startpath(string)]

  frame `frame' {
    tempname tmprow
    gen `tmprow' = _n
    qui levelsof `tmprow' if ID == `session' & Nsessiondofiles!=., local(rownum)
  }
  
  if "`startpath'" == "" {
    local startpath `c(pwd)'
    local startpath = subinstr(`"`startpath'"',"\","/",.)
    c_local startpath `startpath'
  }
  
  file open sessiondo using _sessionsdo/sessions`session'.do, write 
  local datetime_suffix: display %tcCCYYNNDD!THHMMSS clock("`c(current_date)'`c(current_time)'", "DMYhms")
  local logname _sessionslog/session`session'_`datetime_suffix'.log
  file write sessiondo "log using `logname', text name(session`session')" _newline
  file write sessiondo `"cd "`startpath'""' _newline
  if "`graphicson'" == "" {
    file write sessiondo "set graphics off" _newline
  }

  local commondolist 
  foreach c in  `commondo'  {
    file write sessiondo `"do "`c'" "' _newline
  }  
 

  frame `frame': local Ndofiles = Nsessiondofiles[`rownum']
  forvalues f = 1/`Ndofiles' {
    local tmpargs
    foreach a in `arguments' {
      frame `frame': local addarg = `a'[`rownum']
      local tmpargs `"`tmpargs' "`addarg'""'
    }

    frame `frame': local tmpdofile = `dofiles'[`rownum']
    file write sessiondo `"do "`tmpdofile'" `tmpargs' "' _newline
    local rownum = `rownum' + 1
  }
   
  
  file write sessiondo "log close session`session'" _newline
  file close sessiondo  
  return local logname `logname'
end
// -----sessions_create_sessions_do (end)------



// -----sessions_create_tidy_folders (start)------
program define sessions_create_tidy_folders
  syntax, [logdelete]
  // check _sessionsdo  exists and create if needed
  mata: st_local("direxists",strofreal(direxists("_sessionsdo")))
  if !`direxists' mkdir _sessionsdo

  // empty sessionsdo folder  
  mata: sessions_erase_sessionsdo()
  
  // check _sessionslog  exists and create if needed
  mata: st_local("direxists",strofreal(direxists("_sessionslog")))
  if !`direxists' mkdir _sessionslog 
  
  // delete log file of -logdelete- option specified
  if "`logdelete'" != "" mata: sessions_erase_logfiles()
end
// -----sessions_create_tidy_folders (end)------



// -----sessions_getStataexe (start)------
program define sessions_get_stataexe, rclass
  if c(MP)      local StataExe "StataMP"
  else if c(SE) local StataExe "StataSE"
  else          local StataExe "StataBE"

 local statadir `c(sysdir_stata)'
 local StataExe `statadir'`StataExe'-64.exe
 cap confirm file "`StataExe'"
 if _rc {
	 di as error "State executable file could not be found" "Try using sessions init, stataexe()"
   exit 198
 }
 return local StataExe `StataExe'
end
// -----sessions_getStataexe (end)------




////////////////////////////
// ---------------------- //
// -----mata code-------- //
// ---------------------- //
////////////////////////////

mata: 
void sessions_erase_sessionsdo() {
  dofiles = dir("_sessionsdo","files","*")
  for(f=1;f<=rows(dofiles);f++) {
    unlink("_sessionsdo/" + dofiles[f])
  }
}

void sessions_erase_logfiles() {
  logfiles = dir("_sessionslog","files","*")
  for(f=1;f<=rows(logfiles);f++) {
    unlink("_sessionslog/" + logfiles[f])
  }
}

function  find_regex_in_file(string scalar filepath, string scalar pattern)
{
  real scalar fh, found
  string scalar line
    
  fh = fopen(filepath, "r")
    
  // Read line by line until end of file
  found = 0
  while ((line = fget(fh)) != J(0, 0, "")) {
    if (regexm(line, pattern)) {
      found = 1
      break
    }
  }
  fclose(fh)
  return(found)
}

end

////////////////////////////
// ---------------------- //
// -----java code-------- //
// ---------------------- //
////////////////////////////
java , shared(sessions):
import java.io.IOException;
import java.util.ArrayList;
import java.time.LocalDateTime;                  // Import the LocalDateTime class
import java.time.format.DateTimeFormatter;       // Import the DateTimeFormatter class
import com.sun.management.OperatingSystemMXBean; // checking system resources
import java.lang.management.ManagementFactory;   // checking system resources 

// globals 
ArrayList<Process>  SessionList    = new ArrayList<Process>();
ArrayList<String>   StartTime      = new ArrayList<String>();
ArrayList<String>   SessionNames   = new ArrayList<String>();
int Initialized = 0
  
// Sessions class  
public class Sessions {
// -----start new session------ //  
  public static void startsession(String dofile) {
    // build up call to Stata
    List<String> commandList = new ArrayList<>();
    commandList.add(Macro.getGlobal("sessions_STATAEXE"));
    commandList.add("/e");
    if(Macro.getLocal("icon")==null) commandList.add("/i");
    commandList.add("do");
    commandList.add("\"" + dofile + "\"");
    if(Macro.getLocal("frommonitor")==null) {
      for (int a = 1; a <= Integer.parseInt(Macro.getLocal("Narguments")); a++) {
        commandList.add("\"" + Macro.getLocal("arg"+a) + "\"");
      }
    }
    // start process
    ProcessBuilder builder = new ProcessBuilder(commandList);
    try {
      Process newprocess = builder.start();    
      SessionList.add(newprocess);
      StartTime.add(GetStartTime());
      String session_name = Macro.getLocal("name");
      SessionNames.add(session_name);
      String sessionid = "" + SessionList.size();
      System.out.println("Starting Session " + sessionid + " (" + session_name + ")");
    }
    catch (IOException e) {
        e.printStackTrace();
    }
  }
  
// -----kill session------  
  public static void killsession(int id) {
    if(id>SessionList.size()) {
      System.out.println("Session " + id + " does not exist");
      return;      
    }
    if(!SessionList.get(id-1).isAlive()) {
      System.out.println("Session " + id + " is not Running");
      return;
    }
    // kill session using destroy()
    SessionList.get(id-1).destroy();
  }
  
// -----kill all sessions------  
  public static void killallsessions(String id) {
    for (int i = 0; i < SessionList.size(); i++) {
      if(SessionList.get(i).isAlive()) {
         SessionList.get(i).destroy();
      }
    }
  }
  
// -----list sessions-----  
  public static void list_sessions() {
   // Print the list objects in tabular format.
    System.out.println("-----------------------------------------------------------------------------");
    System.out.printf("%4s %10s %12s %12s %12s %2s %-30s", 
                       "ID", "PID", "Date", "Start Time","Status"," ","Session Name");
    System.out.println();
    System.out.println("-----------------------------------------------------------------------------");
    for (int i = 0; i < SessionList.size(); i++) {
        String[] tmp =  StartTime.get(i).split(" ");
        String status = SessionList.get(i).isAlive() ? "Running" : "Finished";
        System.out.format("%4s %10s %12s %12s %12s %2s %-30s",i+1,
                           SessionList.get(i).pid(),
                           tmp[0],tmp[1],status," ",
                           SessionNames.get(i));
        System.out.println();
    }
    System.out.println("-----------------------------------------------------------------------------");
}    
 
// -----resources-----
  public static void resources() {
    OperatingSystemMXBean osBean = ManagementFactory.getPlatformMXBean(
                OperatingSystemMXBean.class);
    double cpuload = 100*osBean.getSystemCpuLoad();
    double total_mem = osBean.getTotalPhysicalMemorySize();
    double free_mem  = osBean.getFreePhysicalMemorySize();
    int Nprocessors = osBean.getAvailableProcessors();
    Macro.setLocal("cpuload",""+cpuload);
    Macro.setLocal("free_mem","" + 100*free_mem/total_mem);
    Macro.setLocal("Nprocessors",""+Nprocessors);
  }
  
// -----sessions_clear-----
  public static void sessions_clear() {
    ArrayList<Process>  SessionList    = new ArrayList<Process>();
    ArrayList<String>   StartTime      = new ArrayList<String>();
    ArrayList<String>   SessionNames   = new ArrayList<String>();
    int Initialized = 0;
  }

// -----get start time-----  
  public static String GetStartTime() {
      LocalDateTime myDateObj = LocalDateTime.now();
      DateTimeFormatter myFormatObj = DateTimeFormatter.ofPattern("yyy-MM-dd HH:mm:ss");
      String formattedDate = myDateObj.format(myFormatObj);
      return formattedDate;  
  }  

  
// -----check if any active sessions------  
  public static void Nsessions() {
    Macro.setLocal("Nsessions",""+SessionList.size());
  }
  
  
// -----check if any active sessions------  
  public static void CheckActiveSession(Integer i) {
    int active = 0;
    if(SessionList.get(i-1).isAlive()) active = 1;
    Macro.setLocal("active",""+active);
  }
  
  
// -----check if any active sessions------  
// currently not used
  public static void AnyActiveSessions() {
    int active = 0;
    for (int i = 0; i < SessionList.size(); i++) {
      if(SessionList.get(i).isAlive()) active = 1;
    }
    Macro.setLocal("anyactive",""+active);
  }

// -----Number of active sessions------  
  public static void NActiveSessions() {
    int Nactive = 0;
    for (int i = 0; i < SessionList.size(); i++) {
      Nactive = Nactive + boolToInt(SessionList.get(i).isAlive());
    }
    Macro.setLocal("Nactive",""+Nactive);
  }

// -----Number of active sessions------  
  public static void Getpid(Integer i) {
    long pid = SessionList.get(i-1).pid();
    Macro.setLocal("pid",""+pid);
  }
  
// -----boolian to integer------
  public static int boolToInt(boolean b) {
      return b ? 1 : 0;
  }
}

end
//---------- _sessions.ado (end) -------------------------------------------------