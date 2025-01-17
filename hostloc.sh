#!/usr/bin/env bash

#原作者：zdszf
##原 https://raw.githubusercontent.com/mixool/script/debian-9/hostloc.sh
#
#Auth：逸笙
#wget https://raw.githubusercontent.com/qkqpttgf/hostloccredit/master/hostloc.sh
#用法1：bash hostloc.sh username password
#用法2：bash hostloc.sh accountfile
#推荐写入crontab:
#43 4 * * * bash /root/hostloc.sh /root/hostlocpsw >/root/hostlog/$(date +\%Y\%m\%d)-log.txt

#微信开发者服务，不用就留空，关注wxpusher获得ID
#可多个，以空格分开
we_no_id=""

#元老号继续,1继续,0不签了
yuanlaogoon=0

# workdir
workdir="/root/hostlog"
[[ ! -d "${workdir}" ]] && mkdir ${workdir}
logpath="/root/hostlog/"
precookiefile="${workdir}/precookiefile"

UA="Mozilla/5.0+(Windows+NT+6.2;+Win64;+x64)+AppleWebKit/537.36+(KHTML,+like+Gecko)+Chrome/74.0.3729.131+Safari/537.36"

delaytime=15

declare -A userpsw
declare -A precredit
declare -A aftcredit
declare -A getcredit
declare -A userlevel
declare -A userUID
declare -A cookies
declare -A strings

#get user info
if [ $# -eq 2 ]; then
  userpsw["$1"]="$2"
fi
if [ $# -eq 1 ]; then
  if [ -s "$1" ]; then
    passfile=$1
    while read line
    do
      if [ g"${line}" != g"" -a g"${line:0:1}" != g"#" -a g"${line:0:1}" != g"@" ]; then
        #echo ${line}
        key1=${line%% *}
        value1=${line#* }
        #echo ${key1},${value1}
        userpsw["${key1}"]="${value1}"
      fi
    done < "${passfile}"
    #usrarry=(`cat $1 | awk '{print $1}'`)
    #pswarry=(`cat $1 | awk '{print $2}'`)
    #for((u=0;u<${#usrarry[*]};u++))
    #do
    #  userpsw["${usrarry[$u]}"]="${pswarry[$u]}"
    #done
  else
    echo 文件 $1 不存在
    exit 1
  fi
fi

#strings
strings[0]="论坛开启了L7FW验证，"
strings[1]="使用SCF计算。"
strings[2]="使用jsshell计算。"
strings[3]="HostLoc访问空间"
strings[4]="论坛元老"

function preconfig() {
  tmp=${workdir}/tmp
  curl -s -H "$UA" "https://hostloc.com/" | grep "slowAES">${tmp}
  if [ -s "${tmp}" ]; then
    echo -n $(date "+%F %T %A") "${strings[0]}"
    remark="${strings[0]}"
    x86_64=`uname -a | grep "86_64"`
    if [ g"${x86_64}" = g"" ]; then
      echo "${strings[1]}"
      remark=${remark}"${strings[1]}\n"
      aa=`cat ${tmp} | awk -F 'a=toNumbers' '{print $2}' | awk -F '"' '{print $2}'`
      bb=`cat ${tmp} | awk -F 'b=toNumbers' '{print $2}' | awk -F '"' '{print $2}'`
      cc=`cat ${tmp} | awk -F 'c=toNumbers' '{print $2}' | awk -F '"' '{print $2}'`
      #echo $aa,$bb,$cc
      #提交abc的值给写好的无服务器函数计算
      L7FW=`curl -s "https://service-27buax72-1258064400.ap-hongkong.apigateway.myqcloud.com/release/nodejstest1?aa="$aa"&bb="$bb"&cc="$cc`
      cookies["L7FW"]=$L7FW
      cookies["path"]='/'
    else
      echo "${strings[2]}"
      remark=${remark}"${strings[2]}\n"
      if [ ! -s "/usr/bin/js" ]; then
        wget -qN "https://raw.githubusercontent.com/github3444/hostloccredit/master/js.tar.gz"
        tar -xzf js.tar.gz
        chmod +x js
        mv js /usr/bin/
        rm -f js.tar.gz
      fi
      if [ ! -s "/usr/bin/libnspr4.so" ]; then
        wget -qN "https://raw.githubusercontent.com/github3444/hostloccredit/master/libnspr4.so"
        chmod +x libnspr4.so
        mv libnspr4.so /usr/bin/
      fi
      if [ ! -s "/usr/bin/libplc4.so" ]; then
        wget -qN "https://raw.githubusercontent.com/github3444/hostloccredit/master/libplc4.so"
        chmod +x libplc4.so
        mv libplc4.so /usr/bin/
      fi
      if [ ! -s "/usr/bin/libplds4.so" ]; then
        wget -qN "https://raw.githubusercontent.com/github3444/hostloccredit/master/libplds4.so"
        chmod +x libplds4.so
        mv libplds4.so /usr/bin/
      fi
      funstr=`cat ${tmp} | awk -F '<script>' '{print $2}' | awk -F ';location.href' '{print $1}'`
      funstr=${funstr/document.cookie=/print(}");"
      aesjs=`cat ${tmp} | awk -F 'src=' '{print $2}' | awk -F '"' '{print $2}'`
      curl -s -H "$UA" --referer "https://www.hostloc.com/" "https://www.hostloc.com"$aesjs --output jstmp
      echo >>jstmp
      echo ${funstr}>>jstmp
      #利用下载的jsshell计算
      cookiestr=`js jstmp | awk -F ';' '{print $1,$2,$3,$4}'`
      for c in ${cookiestr[@]}
      do
        key1=${c%%=*}
        value1=${c#*=}
        cookies[$key1]=$value1
      done
      rm -f jstmp
    fi
    #生成precookie文件
    echo '# Netscape HTTP Cookie File'>${precookiefile}
    echo '# http://curl.haxx.se/docs/http-cookies.html'>>${precookiefile}
    echo '# This file was generated by libcurl! Edit at your own risk.'>>${precookiefile}
    echo>>${precookiefile}
    for key1 in ${!cookies[@]}
    do
    		[ g"$key1" = g"path" ] || echo -e "hostloc.com\tFALSE\t${cookies['path']}\tFALSE\t0\t${key1}\t${cookies[$key1]}">>${precookiefile}
    done
    echo 
  fi
  rm -f ${tmp}

  newuserspace=`curl -s -b ${precookiefile} https://hostloc.com/forum.php | grep -oE "欢迎新会员: <em><a href=\".*\" " | awk -F'\"' '{print $2}'`
  maxuid=`curl -s -b ${precookiefile} https://hostloc.com/${newuserspace} | grep "空间首页" | awk -F 'uid=' '{print $2}' | awk -F '&' '{print $1}'`
  tmpuid=$((maxuid-100))

  startuid=0
  enduid=${maxuid}
  lnum=0
}

function login() {
  username=${user1}
  password=${userpsw[$user1]}
  cookiefile=${workdir}/s_${user1}.cookie
  status=0
  
  echo -n $(date "+%Y-%m-%d %H:%M:%S %A") ${username} 登陆... 
  #echo ${cookiefile}
  data="mod=logging&action=login&loginsubmit=yes&infloat=yes&lssubmit=yes&inajax=1&fastloginfield=username&username=$username&cookietime=$(shuf -i 1234567-7654321 -n 1)&password=$password&quickforward=yes&handlekey=ls"
  curl -s -H "$UA" -c ${cookiefile} -b ${precookiefile} --data "$data" "https://hostloc.com/member.php" | grep "hostloc" >/dev/null && echo "成功" || status=1
  if [ ${status} -eq 1 ]; then
    echo "失败"
    remark=${remark}${user1}" 登陆失败\n"
    ((lnum++))
    continue
  fi
  yourgroup=(`curl -s -H "$UA" -b ${cookiefile} "https://hostloc.com/forum.php" | grep "用户组" | awk -F ':' '{print $2}' | awk -F '<' '{print $1}'`)
  userlevel[${username}]=${yourgroup[0]}
  youruid=(`curl -s -H "$UA" -b ${cookiefile} "https://hostloc.com/home.php?mod=spacecp&ac=credit" | grep -oE "uid=\w*" | awk -F '[=]' '{print $2}'`)
  userUID[${username}]=${youruid[0]}
  echo $(date "+%F %T %A") "${userlevel[${username}]}(UID：${userUID[${username}]})"
}

function logout() {
  logoutlink=`curl -s -H "$UA" -b ${cookiefile} "https://hostloc.com/space-username-${user1}.html" | grep "退出" | awk -F '"' '{print $2}'`
  logoutlink=${logoutlink//&amp;/&}
  #echo ${logoutlink}
  echo -n $(date "+%Y-%m-%d %H:%M:%S %A")
  echo -n " ${user1} "
  curl -s -H "$UA" -b ${cookiefile} "https://hostloc.com/${logoutlink}" | grep -o "您已退出站点"
  rm -f ${cookiefile}
  echo 
  sleep ${delaytime}
}

function passyuanlao() {
  if [ "${userlevel[$user1]}" = "${strings[4]}" ]; then
    echo "$(date "+%F %T %A")" "${strings[4]} 不签"
    remark=${remark}"UID:${userUID[$user1]},\t${user1},\t${userlevel[$user1]},\t不签\n"
    [ -s "${passfile}" ] && sed -i "s/${user1} ${password}/\@${user1} ${password}/" ${passfile}
    logout
    continue
  fi
}

function randuid() {
  rp=0
  viewuid[$a]=${userUID[${username}]}
  while [ ${userUID[${username}]} -eq ${viewuid[$a]} -o $rp -eq 1 ]
  do
    #随机数
    r=`head -200 /dev/urandom | cksum | cut -f1 -d" "`
    viewuid[$a]=$((r%tmpuid+100))
    #跟前几个对比，无重复
    for((ri=0;ri<$a;ri++))
    do
      [ ${viewuid[$ri]} -eq ${viewuid[$a]} ] && rp=1
    done
  done

  #随机间隔时间
  delaytime=$((r%15+5))
  #delaytime=3
}

function credit() {
  creditall=$(curl -s -H "$UA" -b ${cookiefile} "https://hostloc.com/home.php?mod=spacecp&ac=credit&op=base" | grep -oE "积分: </em>\w*" | awk -F'[>]' '{print $2}')
  echo $(date "+%Y-%m-%d %H:%M:%S %A") 目前积分：${creditall}
}

function view() {
  a=0
  viewuid=0
  #echo $(date "+%Y-%m-%d %H:%M:%S %A") 访问空间：
  for((i = $startuid; i <= $enduid; i++))
  do
    randuid
    p=0
    viewuidL='          '${viewuid[$a]}
    viewuidL=${viewuidL:0-${#maxuid}}
    sleep ${delaytime}
    echo -n "$(date "+%Y-%m-%d %H:%M:%S %A")" "${viewuidL}"
    curl -s -H "$UA" -b ${cookiefile} "https://hostloc.com/space-uid-${viewuid[$a]}.html" | grep -o "最近访客" >/dev/null && p=1 || echo " banlist"
    if [ $p -eq 1 ]; then
      ((a++))
      echo -e ",\tok\t$a"
    fi
    [[ $a -eq 10 ]] && break
  done
  #echo $(date "+%Y-%m-%d %H:%M:%S %A") 完成
}

#发送到微信，需要提前赋值we_no_id
#函数需要4个参数，标题、级别、内容、详细内容
function noticetowechat() {
  #echo $1,$2,$3,$4
  data1='{"userIds":['
  for weid in ${we_no_id}
  do
    data1=${data1}'"'${weid}'",'
  done
  data1=${data1:0:-1}
  data1=${data1}'],"template_id":"lpO9UoVZYGENPpuND3FIofNueSMJZs0DMiU7Bl1eg2c","data":{"first":{"value":"'
  data1=${data1}"$1"
  data1=${data1}'","color":"#000099"},"keyword1":{"value":"'
  data1=${data1}"$2"
  data1=${data1}'","color":"#ff00aa"},"keyword2":{"value":"'
  data1=${data1}"$3"
  data1=${data1}'","color":"#ff0000"},"keyword3":{"value":"'
  data1=${data1}"$(date "+%F %T %A")"
  data1=${data1}'","color":"#000000"},"remark":{"value":"'
  data1=${data1}"$4"
  data1=${data1}'","color":"#667766"}}}'
  curl -s -X POST "http://wxmsg.dingliqc.com/send" -d "${data1}" -H "Content-Type:application/json" | grep "处理成功" >/dev/null && echo "$(date "+%F %T %A")" '微信发送成功' || echo "$(date "+%F %T %A")" '微信发送失败'
}

#保留一个月LOG，删除之前的
#需要一个目录作为参数
function dellog() {
  cd $1
  n=`date +%Y%m%d`
  for a in $(ls *log.txt)
  do
    f=${a%%-*}
    #echo $f,$n
    s=$((n-f))
    [ $s -gt 8900 ] && rm -f $a
    if [ $s -lt 8800 ]; then
        [ $s -gt 100 ] && rm -f $a
    fi
  done
}

function main() {
  echo '~START~'
  preconfig
  for user1 in ${!userpsw[*]}
  do
    creditall=0
    login
    [ ${yuanlaogoon} -eq 0 ] && passyuanlao
    credit
    precredit["$user1"]=${creditall}
    view
    credit
    aftcredit["$user1"]=${creditall}
    getcredit["$user1"]=$((aftcredit[${user1}]-precredit[${user1}]))
    remark=${remark}"UID:${userUID[$user1]},\t${user1},\t${userlevel[$user1]},\t${precredit[$user1]}\t+\t${getcredit[$user1]}\t=\t${aftcredit[$user1]}\n"
    [ ${getcredit[$user1]} -lt 20 ] && ((lnum++))
    logout
  done
  
  [ $lnum -eq 0 ] && stat1="正常" || stat1="有问题"
  echo "$(date "+%F %T %A")" "${stat1}"
  remark=${remark:0:-2}
  echo -e "${remark}"
  [ -n "${we_no_id}" ] && noticetowechat "${strings[3]}" "${lnum}" "${stat1}" "${remark}"

  [ -s "${precookiefile}" ] && rm -f ${precookiefile}
  dellog ${logpath}
  echo '~END~'
}

main
