//load utility files. Create a folder called util and add all the script 
//that need to be loaded at startup there. 
@[{system"l ",(getenv[`WSP_CONFIG],"/util/"),raze string x};;{"[ERROR]|",string[.z.P],"|One or more of the util files in the config folder failed to load"}]each key hsym`$(getenv[`WSP_CONFIG],"/util");

//create log.error and log info
{(set) . x}each{flip(key x;value x)}`.log.ERROR`.log.INFO!({[str] -2 raze"[ERROR]|",string[.z.p],"|",str};{[str] -1 raze"[*INFO]|",string[.z.p],"|",str});

//load utility files. Create a folder called util and add all the script 
//that need to be loaded at startup there. 
{@[{system"l ",(getenv[`WSP_CONFIG],"/util/"),raze string x;.log.INFO"File ",string[x]," has been loaded successfully"};
    x;
   {[x;e].log.ERROR"File ",raze[string x]," in the config folder failed to load with error ",e}[x;]]}each a where(a:key hsym`$(getenv[`QFINCONF],"/util"))like"*.q";

.util.buildMapAddr:{
//function to create the dictionary mapping. 
  a:-1_(`$.os.tree[getenv`WSP_HOME])except``.;
  b:a where raze"I"${.os.isFile[string x]}each a;
  b:b where not b like"*/lib/*";
  .util.filemap::({`$last"/"vs string x}each b)!hsym@/:`${ssr[string x;"./";getenv[`WSP_HOME],"/"]}each b;
 }; 

//function to get the working days between two dates. 
.util.workday:{[sd;ed]
   :a where not 0={$[x in(1 0);0;x]}each(a:sd+til 1+ed-sd)mod 7;
 };

 .util.buildMapAddr[];



