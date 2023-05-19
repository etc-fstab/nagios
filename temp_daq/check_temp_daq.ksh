#!/bin/ksh

# Nagios plugin return values
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

# thresholds warn and crit are in F
# F conversion to C
# 20C=68F 22C=72F 24C=75F 26C=79F 28C=82F 
# 30C=86F 32C=89F 34C=93F 36C=97F 38C=100F 40C=104F

err() {
    echo "ERROR: $*"
    exit 1
}

# --- END SCRIPT WITH OUTPUT
endscript () {
    echo "${RESULT}"
    exit ${EXIT_STATUS}
}

usage() {
    RESULT="$0 <temper_module_name> <warn>F <crit>F"
    EXIT_STATUS="${STATE_UNKNOWN}"
    endscript
}

temper_module=$1
temper_warn=$2
temper_crit=$3

# check if there are three arguments
if [ $# -ne 3 ]; then
    usage
fi

# check if critical is greater then warning
if [ ${temper_crit} -eq ${temper_warn} -o ${temper_crit} -lt ${temper_warn} ]; then
    err "Critical ${temper_crit}F must be greater then warning ${temper_warn}F."
fi

temper_f=`curl -s http://${temper_module}/state.xml | grep -o -P '(?<=<sensor1temp>).*(?=</sensor1temp>)'`

# check if result is null
if [ -z ${temper_f} ]; then
    RESULT="Cannot get temperature for ${temper_module}"
    EXIT_STATUS="${STATE_UNKNOWN}"
fi

if [ ${temper_f} -gt ${temper_crit} ]; then
    RESULT="CRITICAL ${temper_f}F for ${temper_module} | Temp=${temper_f};${temper_warn};${temper_crit}"
    EXIT_STATUS="${STATE_CRITICAL}"
elif [ ${temper_f} -lt ${temper_warn} ]; then
    RESULT="OK ${temper_f}F for ${temper_module} | Temp=${temper_f};${temper_warn};${temper_crit}"
    EXIT_STATUS="${STATE_OK}"
else
    RESULT="WARNING ${temper_f}F for ${temper_module} | Temp=${temper_f};${temper_warn};${temper_crit}"
    EXIT_STATUS="${STATE_WARNING}"
fi

# finish the script
endscript

