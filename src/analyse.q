//--------------------------------------------------------------------------------------------------
//##################################################################################################
// STARTING THE SCRIPT                                                                            ##
//                                                                                                ##
// q analyse.q -filename Expense_Report.csv -p 5000                                               ##
//                                                                                                ##
//##################################################################################################
//     IDEAS                                                                                      ##
//                                                                                                ##
// 1. Get the csv file using the zoho expense API                                                 ##
//##################################################################################################

//##################################################################################################
//     DEFAULT VARIABLES                                                                          ##
//##################################################################################################
//\l email.q
//\l os.q

.log.ERROR:{"[ERROR]|",string[.z.p],"| ",x};
.log.INFO:{"[*INFO]|",string[.z.p],"| ",x};

.analytics.args:.Q.opt .z.x; 
.analytics.args[`daysinmonth]:(`01`02`03`04`05`06`07`08`09`10`11`12)!
  (31;28;31;30;31;30;31;31;30;31;30;31);
.analytics.requiredfields:`report_name`expense_date`expense_amount`expense_category`merchant_name; 
.analytics.castfields:.analytics.requiredfields!({lower x};{"D"$ssr[string x;"-";"."]};
	{"F"$string x};{`$lower ssr[ssr[string x;" ";"_"];"/";"_"]};{lower ssr[string x;" ";"_"]}); 
.analytics.weekdays:`Saturday`Sunday`Monday`Tuesday`Wednesday`Thursday`Friday;

system"export LD_LIBRARY_PATH=PATH";
//loading the q.q file 
@[system;"l ",getenv`QINIT;{.log.ERROR"Failed to load q.q file with error ",x," ..."}];

//##################################################################################################
//     DEFINING FUNCTIONS                                                                         ##
//##################################################################################################
getfields:{
  .log.INFO"Executing getfield ... ";
  //I don't think this function is needed anymore.
  .analytics.colsincsv::`$lower ssr[;" ";"_"]each","vs((read0 @/:.util.filemap first`$x)0);   
  .analytics.parser::count[.analytics.colsincsv]#"S"; 
  }; 

loadConfigFiles:{[x;y]
  .log.INFO"Executing loadConfigFiles ...";
  //function to load config files
  tp:raze exec types from(("S*";enlist"|")0:.util.filemap`configProfile.psv)where file in x;
  :(raze tp;enlist(",";"|")`psv~y)0:.util.filemap x; 
 };

casttable:{
  .log.INFO"Executing casttable ...";
  //function to cast fields to their right types using the .analytics.castfields
  {[col]{![z;();0b;(enlist x)!enlist ((';y);x)]}[col;.analytics.castfields[col];`.analytics.data]}'
    [cols .analytics.data]
  };

loadfile:{
  .log.INFO"Executing loadfile ...";
  //function to load the expense csv
  .analytics.data:(.analytics.parser;enlist",")0:.util.filemap first`$.analytics.args`filename;
  .analytics.data:(`${lower ssr[string x;" ";"_"]}each cols .analytics.data)xcol .analytics.data; 
  .analytics.data::.analytics.requiredfields#.analytics.data; 
  };

getdaysofmonth:{[]
  .log.INFO"Executing getdaysofmonth ...";
  $[`month in key .analytics.args;
    "I"$first .analytics.args[`month];
    [a:exec expense_date from .analytics.data;
     if[(1<count distinct `month$a)or 1<count distinct `year$a;
        '"getdaysofmonth: There seems to be more months/years in the dataset. Please check ..."];
     mnth:first distinct`mm$a;year:first distinct`year$a]
    ]; 
  dim:.analytics.args[`daysinmonth]`$-2#"0",string mnth; 
  :("D"$"."sv string(year;mnth;1))+til dim; 
 }; 

formattableHTML:{[table]
  //function to format the table for HTML output
  header:raze"<tr>",({"<th>",string[x],"</th>"}each cols table),"</tr>"; 
  rows:{[table;x] "<tr>",raze{"<td>",x,"</td>"}'[string value(0!table)[x]],"</tr>"}[table]
    '[til count table]; 
  :raze"<table>",header,rows,"</table>";
  };

pivTab:{[pCol]
  .log.INFO"Executing pivTab ...";
  //create table to pivot on 
  holiday:loadConfigFiles[`holidays.csv;`csv];
  P:asc exec distinct expense_category from .analytics.data; 
  pvt:exec P#(expense_category!expense_amount) by expense_date:expense_date from .analytics.data;
  res:0f^(lj/)[([expense_date:getdaysofmonth[]]meals_and_entertainment:count[getdaysofmonth[]]#0f;
  	train_bus_tube:count[getdaysofmonth[]]#0f);{[x] ?[.analytics.data;enlist(in;`expense_category;enlist x);
  	(enlist`expense_date)!enlist`expense_date;(enlist x)!enlist(sum;`expense_amount)]}'[exec distinct expense_category 
  	from .analytics.data]];
  res:(update wd:{?[any(`Saturday`Sunday)~\:x;`free;`work]}'[dow]from update 
  	dow:(.analytics.weekdays mod[exec expense_date from res;7])from res)lj`expense_date xkey 
    update wd:`free from select expense_date:date from holiday;
  :`wd`dow`expense_date`stat xkey update stat:{[x;y]$[(`free~x)&y>0;`warn;`]}'[wd;meals_and_entertainment]from res;
 };

.snapshot.make:{[t]
  .log.INFO"Executing .snapshot.make ...";
  .snapshot.table:`wd`dow`expense_date`difference`stat xkey 
    update difference:25-meals_and_entertainment 
    from(0!t)where wd in`work; 
  
  .snapshot.totalAllowance:25*exec count i from t where wd in`work;
  .snapshot.totalSpent:exec sum meals_and_entertainment from t; 
  .snapshot.differenceToDate:(exec 25*count i from t where wd in `work,expense_date<.z.d) - 
    exec sum meals_and_entertainment from t where expense_date<.z.d;
  .snapshot.totalLeft:.snapshot.totalAllowance - .snapshot.totalSpent; 
  .snapshot.avgPDay:exec %[sum meals_and_entertainment;count i]from select from .snapshot.table 
    where wd in`work,expense_date<=.z.d;
  .snapshot.daysOff:exec count i from .snapshot.table where wd in`free;
  .snapshot.weekendDays:exec count i from .snapshot.table where dow in`Sunday`Saturday;  
  .snapshot.maxDayDict:exec from .snapshot.table where meals_and_entertainment=max meals_and_entertainment;
  .snapshot.warnDates:exec expense_date from(0!.snapshot.table)where stat in`warn;
  .snapshot.overDates:exec expense_date from .snapshot.table where meals_and_entertainment>25; 
 };

.snapshot.cutBy:{[cBy;msg;arr]
  //function to cut arrays by give number
  getCut:cBy cut arr;
  getCntChars:count msg;  
  {[msg;cChars;x;arr]a:", "sv string arr; -1 $[not x;msg,a;(cChars#" "),a]}[msg;getCntChars]'[til count getCut;getCut]; 
  };

.snapshot.display:{
  //function to create report 
  -1" ";
  -1" =======================================================================================";
  -1"                              DISPLAYING EXPENSES";
  -1" =======================================================================================";
  -1" ";
  -1" DATE: ",string .z.d;
  -1" TIME: ",string .z.t;
  -1" ";
  -1" Total allowance for this month : ",string .snapshot.totalAllowance;
  -1" Total spent so far             : ",string .snapshot.totalSpent;
  -1" Total left to spend            : ",string .snapshot.totalLeft;
  -1" Average spent per day          : ",string .snapshot.avgPDay;
  -1" Most spent in one day          : ",string[.snapshot.maxDayDict`meals_and_entertainment]," on ",string[.snapshot.maxDayDict`dow]," : ",string[.snapshot.maxDayDict`expense_date];
  -1" Number of days off             : ",string .snapshot.daysOff;
  -1" Number of weekend days         : ",string .snapshot.weekendDays;
  -1" Number of holidays             : ",string .snapshot.daysOff - .snapshot.weekendDays;
  .snapshot.cutBy[4;" Number of warns in report      : ",(-2#"0",string[count .snapshot.warnDates])," : ";.snapshot.warnDates];
  .snapshot.cutBy[4;" Number of dates amount exceeded: ",string[count .snapshot.overDates]," : ";.snapshot.overDates];
  -1" ";
  -1" =======================================================================================";
  -1"                                END OF DISPLAY";
  -1" =======================================================================================";
  -1" ";
  -1" Executed in: ",string x;
  };

//##################################################################################################
//     MAIN                                                                                       ##
//##################################################################################################
main:{[]
  startTime:.z.p; 
  .log.INFO"Executing main ...";
  //.email.connect `url`user`password`from`usessl`debug!(.email.url;.email.user;.email.password;
  //.email.from;.email.usessl;.email.debug);
  getfields[.analytics.args`filename];
  loadfile[];  
  casttable[];
  .snapshot.make pivTab[`expense_category];
  .snapshot.display[.z.p-startTime];
   //mail::"<html><head></head><body>",formattableHTML[foodspendingbyday],"</body></html>";
   //{.email.send[`to`subject`body`debug!(`$"testmail";"TESTMAIL";x;1i)]}[mail];
 }; 

$[system"e";main[];@[main;::;{.log.ERROR"main: Function has failed to run with error ",x}]];

//--------------------------------------------------------------------------------------------------
