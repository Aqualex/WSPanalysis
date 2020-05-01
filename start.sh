#!/bin/bash

export QINIT=$WSP_QINIT

$RLWRAP $HOME/q/l64/q $WSP_SRC_ANALYSE -filename Expense_Report.csv -createReport -c 200 200 -p 5001 -e 1

#$RLWRAP $HOME/q/l64/q $WSP_SRC_ANALYSE -filename Expense_Report.csv -c 200 200 -p 5001
