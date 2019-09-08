#!/bin/bash

export QINIT=$WSP_QINIT

$RLWRAP $HOME/q/l64/q $WSP_SRC_ANALYSE -filename Expense_Report.csv -c 200 200 -p 5000
#$RLWRAP $HOME/q/l64/q $WSP_SRC_ANALYSE -allowanceperday 25 -filename Expense_Report.csv -month 07 -holiday 2019.06.04 2019.06.05 -c 200 200 -p 5000
