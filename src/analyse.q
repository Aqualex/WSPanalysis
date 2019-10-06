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

.analytics.args:.Q.opt .z.x; 
.analytics.args[`daysinmonth]:(`01`02`03`04`05`06`07`08`09`10`11`12)!
  (31;28;31;30;31;30;31;31;30;31;30;31);
.analytics.requiredfields:`report_name`expense_date`expense_amount`expense_category`merchant_name; 
.analytics.castfields:.analytics.requiredfields!({lower x};{"D"$ssr[string x;"-";"."]};
	{"F"$string x};{`$lower ssr[ssr[string x;" ";"_"];"/";"_"]};{lower ssr[string x;" ";"_"]}); 
.analytics.weekdays:`Saturday`Sunday`Monday`Tuesday`Wednesday`Thursday`Friday;

system"export LD_LIBRARY_PATH=PATH";
//loading the q.q file 
@[system;
  "l ",getenv`QINIT;
  {.log.ERROR"Failed to load q.q file with error ",x," ..."}
  ];

//##################################################################################################
//     DEFINING FUNCTIONS                                                                         ##
//##################################################################################################
getfields:{
  //I don't think this function is needed anymore.
  .analytics.colsincsv::`$lower ssr[;" ";"_"]each","vs((read0 @/:.util.filemap first`$x)0);   
  .analytics.parser::count[.analytics.colsincsv]#"S"; 
  }; 

loadConfigFiles:{[x;y]
  //function to load config files
  tp:raze exec types from(("S*";enlist"|")0:.util.filemap`configProfile.psv)where file in x;
  :(raze tp;enlist(",";"|")`psv~y)0:.util.filemap x; 
 };

casttable:{
  //function to cast fields to their right types using the .analytics.castfields
  {[col]{![z;();0b;(enlist x)!enlist ((';y);x)]}[col;.analytics.castfields[col];`.analytics.data]}'
    [cols .analytics.data]
  };

loadfile:{
    //function to load the expense csv
    .analytics.data:(.analytics.parser;enlist",")0:.util.filemap first`$.analytics.args`filename;
    .analytics.data:(`${lower ssr[string x;" ";"_"]}each cols .analytics.data)xcol .analytics.data; 
    .analytics.data::.analytics.requiredfields#.analytics.data; 
  };

getdaysofmonth:{[]
  $[`month in key .analytics.args;
    "I"$first .analytics.args[`month];
    [a:exec expense_date from .analytics.data;
     if[(1<count distinct `month$a)or 1<count distinct `year$a;
        '"getdaysofmonth: There seems to be more months/years in the dataset. Please check ..."];
     mnth:first distinct`mm$a;year:first distinct`year$a]
    ]; 
  dim:.analytics.args[`daysinmonth]`$"0",string mnth; 
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
  //create table to pivot on 
  holiday:loadConfigFiles[`holidays.csv;`csv];
  P:asc exec distinct expense_category from .analytics.data; 
  pvt:exec P#(expense_category!expense_amount) by expense_date:expense_date from .analytics.data;
  res:0f^(lj/)[([expense_date:getdaysofmonth[]]meals_and_entertainment:count[getdaysofmonth[]]#0f;
  	train_bus_tube:count[getdaysofmonth[]]#0f);{[x] ?[.analytics.data;enlist(in;`expense_category;enlist x);
  	(enlist`expense_date)!enlist`expense_date;(enlist x)!enlist(sum;`expense_amount)]}'[exec distinct expense_category 
  	from .analytics.data]];
  res:(update wd:{?[any(`Saturday`Sunday)~\:x;`free;`work]}'[dow]from update dow:(.analytics.weekdays mod[exec expense_date from res;7])from res)lj`expense_date xkey update wd:`free from select expense_date:date from holiday;
  :`wd`dow`expense_date`stat xkey update stat:{[x;y]$[(`free~x)&y>0;`warn;`]}'[wd;meals_and_entertainment]from res;
 };

.snapshot.make:{[t]
  .snapshot.table:`wd`dow`expense_date`difference`stat xkey 
    update difference:25-meals_and_entertainment 
    from(0!t)where wd in`work; 
  
  .snapshot.totalAllowance:25*exec count i from t where wd in`work;
  
  .snapshot.totalSpent:exec sum meals_and_entertainment from t; 
  
  .snapshot.differenceToDate:(exec 25*count i from t where wd in `work,expense_date<.z.d)-exec sum meals_and_entertainment from t where expense_date<.z.d;
 };

//##################################################################################################
//     MAIN                                                                                       ##
//##################################################################################################
main:{[]
  //.email.connect `url`user`password`from`usessl`debug!(.email.url;.email.user;.email.password;
  //.email.from;.email.usessl;.email.debug);
  getfields[.analytics.args`filename];
  loadfile[];  
  casttable[];
  .snapshot.make pivTab[`expense_category];
   //mail::"<html><head></head><body>",formattableHTML[foodspendingbyday],"</body></html>";

   //{.email.send[`to`subject`body`debug!(`$"testmail";"TESTMAIL";x;1i)]}[mail];
 }; 

//$[system"e";main[];@[main;::;{.log.ERROR"main: Function has failed to run with error ",x}]];

//--------------------------------------------------------------------------------------------------
