#!/bin/bash

# "include" the set of common script functions
source common.bash


declare -i b_tunnelUse=0
declare -i b_localEcho=0
declare -i b_errorSink=0
declare -i b_detach=0
declare -i sleepBetweenLoop=0
declare -i b_continueProcessing=0
declare -i b_cmdSuffix=0
declare -i COLWIDTH=25
tunnelUser="rudolph"
tunnelHost="localhost"
tunnelPort=4216
hostIgnore=""
onlyTheseHosts=""
macro=""
suffix=""

bg="black"
fg="purple"
user="rudolphpienaar"

GROUP=PICES

source machines.sh

G_SYNOPSIS="

  NAME

        net-run.sh

  SYNOPSIS

        net-run.sh      [-G <computeGroup>]                             \\
                        [-u <user>]                                     \\
                        [-U <tunnelUser>]                               \\
                        [-P <tunnelPort>]                               \\
                        [-H <tunnelHost>]                               \\
                        [-I <ignoreHostList>]                           \\
                        [-O <onyTheseHosts>]                            \\
		                [-s <sleepBetweenLoop>]                         \\
                        [-v <verbosityLevel>]                           \\
                        [-E]                                            \\
                        [-L]                                            \\
                        [-B]                                            \\
                        [-S <macro[,]>]                                 \\
                        [-c <appendCmd>]                                \\
                        [-W <COLWIDTH>]                                 \\
                        -C <cmd>

  DESC

        'net-run.sh' simply runs the <cmd> on each specified machine in
        the <computeGroup>.

  ARGS

        -C <cmd>
        The command to exeute on each host in <group>.

        [-c <appendCmd>]
        A command to run after suffixing to the PRE string.

        [-W <COLWIDTH>]
        Width of each column.

        [-S <macro[,]>]
        Comma separated list of <cmd> macros to run. These include:

                * uptime
                * processors
                * memInfo
                * prettyName
                * osver
                * bogomips
                * uname
                * top
        * who
        * user

        For each <macro>, the results will be presented in column
        dominant tabular form.

        [-E]
        If set, append a \"2>/dev/null\" to the source ssh. This effectively
        mutes any stdout from the remote process.

        [-L]
        If set, echo local command.

        [-B]
        If set, detach each command.

        [-G <group>]
        The computing group to monitor. Valid choices are PICES and FNNDSC.

        [-I <ignoreHostList>]
        A comma separated list of hosts in the compute group to ignore, i.e.
        these hosts are skipped during remote execution.

        [-O <onlyTheseHosts>]
        A comma separated list of hosts within a group to examine.

        [-u <user>]
        Remote ssh user -- typically the user on the remote host on
        which the xload process will run.

        [-U <tunnelUser>]
        If access to the remote host is via an ssh tunnel, this
        arg denotes the tunnel user name.

        [-H <tunnelHost>]
        If access to the remote host is via an ssh tunnel, this
        arg denotes the tunnel origin host.

        [-P <tunnelPort>]
        If access to the remote host is via an ssh tunnel, this
        arg denotes the tunnel port on <tunnelHost>.

        [-s <sleepBetweenLoop>]
        If specified, sleep <sleepBetweenLoop> seconds during each program
        loop. This improves ssh tunnel performance.

  EXAMPLES

      LONG STYLE

        Quoting can be tricky!

        Speed can be an issue with large environments. You can send a -B
        to run each ssh in the background. It is usually a good idea to
        also a <sleepBetweenLoop> for better timing.

        * Determine the uptime of all hosts in an env:

        printf '\n%${C}s' hostname ; printf '%15s\n' Uptime ;
        net-run.sh -G FNNDSC -C \"source ~rudolphpienaar/.bashrc ;
                                  hostname |
                                  xargs -i@ printf '%${C}s' @ ;
                                  uptime\" -E

        * Determine the number of processors in an env:

        printf '\n%${C}s' hostname ; printf '%15s\n' Processors ;
        net-run.sh -G FNNDSC -C \"source ~rudolphpienaar/.bashrc ;
                                  hostname |
                                  xargs -i@ printf '%${C}s: ' @ ;
                                  cat /proc/cpuinfo |
                                  grep processor |
                                  wc -l | xargs -i@ echo ' '@\" -E

        * Determine the OS ver:

        printf '\n%${C}s' hostname ; printf '%15s\n' OSver ;
        net-run.sh -G FNNDSC -C \"source ~rudolphpienaar/.bashrc ;
                                  hostname |
                                  xargs -i@ printf '%${C}s: ' @ ;
                                  cat /etc/issue.net\" -E

        * OS name etc:

        printf '\n%${C}s' hostname ; printf '%15s\n' PrettyName ;
        net-run.sh -G FNNDSC -C \"source ~rudolphpienaar/.bashrc ;
                                  hostname |
                                  xargs -i@ printf '%${C}s: ' @ ;
                                  cat /etc/os-release |
                                  grep -E 'PRETTY'|
                                  sed 's|PRETTY_NAME=||' \" -E

        * Determine the uname:

        printf '\n%${C}s' hostname ; printf '%15s\n' uname ;
        net-run.sh -G FNNDSC -C \"source ~rudolphpienaar/.bashrc ;
                                  hostname |
                                  xargs -i@ printf '%${C}s ' @ ;
                                  uname -a\" -E

        * Determine the total memory:

        printf '\n%${C}s' hostname ; printf '%15s\n' memTotal ;
        net-run.sh -G FNNDSC -C \"source ~rudolphpienaar/.bashrc ;
                                  hostname |
                                  xargs -i@ printf '%${C}s ' @ ;
                                  cat /proc/meminfo |
                                  grep MemTotal |
                                  sed 's|MemTotal:||' |
                                  xargs -i@ printf '%15s\n' @\" -E

        * Determine the load average:

        printf '\n%${C}s' hostname ; printf '%15s\n' loadavg ;\\
        net-run.sh -G FNNDSC -C \"source ~rudolphpienaar/.bashrc ;
                                  hostname |
                                  xargs -i@ printf '%${C}s: ' @ ;
                                  cat /proc/loadavg \" -E

        * Top highest consuming apps:

        net-run.sh -G FNNDSC -C \"source ~rudolphpienaar/.bashrc ;
                                  hostname |
                                  xargs -i@ printf '%${C}s: ' @ ;
                                  ps aux | sort -nrk 3,3 |
                                  head -n 1 \" -E

        * apt tools:

        net-run.sh -G FNNDSC -C \"source ~rudolphpienaar/.bashrc ;
                                  hostname |
                                  xargs -i@ printf '%${C}s: ' @ ;
                                  sudo apt update \" -E
        * bogomips:

        printf '\n%${C}s' hostname ; printf '%15s\n' bogomips ;\\
        net-run.sh -G FNNDSC -C \"source ~rudolphpienaar/.bashrc ;
                                  hostname |
                                  xargs -i@ printf '%${C}s' @ ;
                                  cat /proc/cpuinfo |
                                  grep bogo |
                                  sed 's|bogomips||' | sed 's|:||' |
                                  tail -n 1\" -E

    MACRO STYLE

    net-run.sh -G FNNDSC -S uptime -E -s 1

"

function macro_process
{
    CW=$COLWIDTH
    PRE="source ~rudolphpienaar/.bashrc ; hostname |
                                          xargs -i@ printf '%${CW}s| ' @"
    l_macro=$(echo $1 | tr ',' ' ')
    printf "\n%${CW}s|" hostname
    cmd=$PRE
    for macro in $l_macro; do
        case $macro
        in
            "uptime")       printf "%${CW}s|" $macro;
                            cmd="$cmd ;     uptime                          |
                                            tr '\n' '|'"                    ;;
            "processors")   printf "%${CW}s|" $macro;
                            cmd="$cmd ;     cat /proc/cpuinfo               |
                                            grep processor                  |
                                            wc -l | xargs -i@ echo ' '@     |
                                            tr '\n' '|'"                    ;;
            "osver")        printf "%${CW}s|" $macro;
                            cmd="$cmd;      cat /etc/issue.net              |
                                            tr '\n' '|'"                    ;;
            "prettyname")   printf "%${CW}s|\t" $macro;
                            cmd="$cmd;      cat /etc/os-release             |
                                            grep -E 'PRETTY'                |
                                            sed 's|PRETTY_NAME=||'          |
                                            tr '\n' '|'"                    ;;
            "uname")        printf "%${CW}s|" $macro;
                            cmd="$cmd;      uname -a                        |
                                            tr '\n' '|'"                    ;;
            "meminfo")      printf "%${CW}s|" $macro;
                            cmd="$cmd;      cat /proc/meminfo               |
                                            grep MemTotal                   |
                                            sed 's|MemTotal:||'             |
                                            sed 's|^[[:space:]]*||'         |
                                            xargs -i@ printf '%12s\n' @     |
                                            tr '\n' '|'"                    ;;
            "loadavg")      printf "%${CW}s|" $macro;
                            cmd="$cmd;      cat /proc/loadavg               |
                                            tr '\n' '|'"                    ;;
            "bogomips")     printf "%${CW}s|" $macro;
                            cmd="$cmd;      cat /proc/cpuinfo               |
                                            grep bogo                       |
                                            sed 's|bogomips||'              |
                                            sed 's|:||'                     |
                                            sed 's|^[[:space:]]*||'         |
                                            tail -n 1                       |
                                            tr '\n' '|'"                    ;;
            "CPU")          printf "%${CW}s|" $macro;
                            cmd="$cmd;      cat /proc/cpuinfo               |
                                            grep name                       |
                                            sed 's|model name||'            |
                                            sed 's|:||'                     |
                                            sed 's|^[[:space:]]*||'         |
                                            tail -n 1                       |
                                            tr '\n' '|'"                    ;;
            "who")          printf "%${CW}s|" $macro;
                            cmd="$cmd;      who                             |
                                            head -n 1                       |
                                            tr '\n' '|'"                    ;;
            "user")         printf "%${CW}s|" $macro;
                            cmd="$cmd;      who                             |
                                            head -n 1                       |
                                            sed 's/\(.*\)\(. \) \(.*\)/\1/' |
                                            tr '\n' '|'"                    ;;
            "top")          printf "%${CW}s|" $macro;
                            cmd="$cmd;      ps aux | sort -nrk 3,3          |
                                            head -n 1                       |
                                            tr '\n' '|'"                    ;;
            *)
                echo "The following macros are understood:"
                echo -e "\n\tuptime processors osver prettyname uname meminfo loadavg bogomips CPU who top"
                echo -e "\nExiting to system with code '1'."
                exit 1
        esac
    done
    printf "\n"
}

function suffix_process
{
    PRE="source ~rudolphpienaar/.bashrc ; hostname |
                                          xargs -i@ printf '%${COLWIDTH}s\t ' @"
    cmd="$PRE; $1"
    printf "\n%${COLWIDTH}s" hostname ; printf ' %s\n' "$1" ;
}



while getopts u:R:C:v:U:H:P:G:s:ELBI:O:S:c:W: option ; do
    case "$option"
    in
        u) user=$OPTARG                 ;;
        W) COLWIDTH=$OPTARG             ;;
        E) b_errorSink=1                ;;
        L) b_localEcho=1                ;;
        B) b_detach=1                   ;;
        I) hostIgnore=$OPTARG           ;;
        O) onlyTheseHosts=$OPTARG       ;;
        U) tunnelUser=$OPTARG
           b_tunnelUse=1                ;;
        H) tunnelHost=$OPTARG
           b_tunnelUse=1                ;;
        P) tunnelPort=$OPTARG
           b_tunnelUse=1                ;;
        G) GROUP=$OPTARG                ;;
        v) Gi_verbose=$OPTARG           ;;
        s) sleepBetweenLoop=$OPTARG     ;;
        S) macro=$OPTARG                ;;
        C) cmd="$OPTARG"                ;;
        c) suffix="$OPTARG"
       b_cmdSuffix=1                    ;;
        \?) synopsis_show
            exit 1;;
    esac
done

if (( ${#macro} )) ; then
    macro_process $macro
fi

if (( b_cmdSuffix )) ; then
    suffix_process "$suffix"
fi

case $GROUP
in
        PICES)  a_HOST=("${a_PICES[@]}")        ;;
        FNNDSC) a_HOST=("${a_FNNDSC[@]}")       ;;
esac

declare -i i=0

ERRORSINK=""
DETACH=""
origUser=$user
if (( b_errorSink ))    ; then ERRORSINK="2>/dev/null"    ; fi
if (( b_detach ))       ; then DETACH="&"                 ; fi
for host in "${a_HOST[@]}" ; do
    if grep -q $host <<<"$hostIgnore" ; then
        continue
    fi
    if (( ${#onlyTheseHosts} )) ; then
        b_continueProcessing=0
        if grep -q $host <<<"$onlyTheseHosts" ; then
            b_continueProcessing=1
        fi
    else
        b_continueProcessing=1
    fi
    if (( b_continueProcessing )) ; then
        if [[ "$host" == "tautona" ]] ; then
            user=rpienaar
        else
            user=$origUser
        fi
        CMD="ssh -X $user@$host \"$cmd\" $ERRORSINK $DETACH"
        if (( b_tunnelUse )) ; then
                CMD="ssh -X $user@$host \"\\\""$cmd\"\\"\" $ERRORSINK $DETACH"
        fi
        #echo "b_tunnelUse=$b_tunnelUse"
        if (( b_tunnelUse )) ; then
            CMD="ssh -p $tunnelPort ${tunnelUser}@${tunnelHost} $CMD"
        fi
        if (( b_localEcho )); then echo $CMD ; fi
        # Grab output of remote call
        STR=$(eval "$CMD")
        # Remove last string "|"
        STR=${STR%?}
        if (( ${#STR} )) ; then
           # Now add spacing/formatting...
           echo "$STR" | awk -v CW=$COLWIDTH -F \| '{
           for(i=1; i<=NF; i++)
               printf("%*s|", CW, $i);
           printf("\n");}'
           ((i++))
        fi
        if (( sleepBetweenLoop )) ;  then
            sleep $sleepBetweenLoop
        fi
    fi
done





