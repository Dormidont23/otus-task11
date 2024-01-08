#!/bin/bash

function my_ps()
{
  # Числовое имя каталога = ID процесса. Составляем список таких каталогов
  pid_array=`ls /proc | grep -E '^[0-9]+$'`
  # Надо для дальнейшего вычисления времени CPU
  clock_ticks=$(getconf CLK_TCK)

  clear
  printf "%-6s %-6s %-10s %-4s %-6s %-4s %-7s %-18s\n" "PID" "PPID" "USER" "PR" "STATE" "THR" "%CPU" "COMMAND"

  for pid in $pid_array; do
    # Если есть права на чтение файла stat, тогда продолжаем
    if [ -r /proc/$pid/stat ]; then
      # Вытаскиваем в массив значения из файла stat
      stat_array=(`cat /proc/$pid/stat`)
      uptime_array=(`cat /proc/uptime`)
      # Командная строка процесса
      comm=(`cat /proc/$pid/cmdline`)
      # Для некотрых процессов в файле cmdline нет информации, поэтому смотрим файл status
      if [ "$comm" = '' ]; then
        comm="[`awk '/Name/{print $2}' /proc/$pid/status`]"
      fi
      # Выковыриваем id юзера
      user_id=(`cat /proc/$pid/status | grep Uid | awk '{print $2}'`)
      # Получаем имя юзера
      user=$(id -nu $user_id)
      # Время работы системы
      uptime=${uptime_array[0]}
      # Статус процесса
      state=${stat_array[2]}
      # ID родительского процесса
      ppid=${stat_array[3]}
      # Приоритет процесса
      priority=${stat_array[17]}

      # Эти значения нужны для вычисления загрузки CPU
      utime=${stat_array[13]}
      stime=${stat_array[14]}
      cutime=${stat_array[15]}
      cstime=${stat_array[16]}
      starttime=${stat_array[21]}
      # Количество потоков
      num_threads=${stat_array[19]}

      total_time=$(($utime + $stime + $cstime))
      seconds=$(awk 'BEGIN {print ('$uptime' - ('$starttime' / '$clock_ticks'))}')
      # Считаем загрузку процессора в процентах
      cpu_usage=$(awk 'BEGIN {print (100 * (('$total_time' / '$clock_ticks') / '$seconds'))}')
      printf "%-6d %-6d %-10s %-4d %-4s %-4u %-7.2f %-18s\n" $pid $ppid $user $priority $state $num_threads $cpu_usage $comm
    fi
  done
}

case "$1" in
  ax) my_ps;;
  *) echo -e "Недопустимая команда.\nПример использования: ps1.sh ax";;
esac