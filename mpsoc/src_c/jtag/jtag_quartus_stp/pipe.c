/* 
   Copyright (C) Andrew Tridgell 1996
   Copyright (C) Paul Mackerras 1996
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/

/*
  Utilities used in rsync 

  tridge, June 1996
  */

#ifndef _PIPE_H_
#define _PIPE_H_

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#define STDIN_FILENO	0
#define STDOUT_FILENO	1

pid_t do_fork(void);

void exit_cleanup(int value) {
	exit(value);
}

/* this is taken from CVS */
int piped_child(char **command,int *f_in,int *f_out)
{
  int pid;
  int to_child_pipe[2];
  int from_child_pipe[2];

  if (pipe(to_child_pipe) < 0 ||
      pipe(from_child_pipe) < 0) {
    fprintf(stderr,"pipe: %s\n",strerror(errno));
    exit_cleanup(1);
  }


  pid = do_fork();
  if (pid < 0) {
    fprintf(stderr,"fork: %s\n",strerror(errno));
    exit_cleanup(1);
  }

  if (pid == 0)
    {
      if (dup2(to_child_pipe[0], STDIN_FILENO) < 0 ||
	  close(to_child_pipe[1]) < 0 ||
	  close(from_child_pipe[0]) < 0 ||
	  dup2(from_child_pipe[1], STDOUT_FILENO) < 0) {
	fprintf(stderr,"Failed to dup/close : %s\n",strerror(errno));
	exit_cleanup(1);
      }
      if (to_child_pipe[0] != STDIN_FILENO) close(to_child_pipe[0]);
      if (from_child_pipe[1] != STDOUT_FILENO) close(from_child_pipe[1]);
      execvp(command[0], command);
      fprintf(stderr,"Failed to exec %s : %s\n",
	      command[0],strerror(errno));
      exit_cleanup(1);
    }

  if (close(from_child_pipe[1]) < 0 ||
      close(to_child_pipe[0]) < 0) {
    fprintf(stderr,"Failed to close : %s\n",strerror(errno));   
    exit_cleanup(1);
  }

  *f_in = from_child_pipe[0];
  *f_out = to_child_pipe[1];
  
  return pid;
}


static pid_t all_pids[10];
static int num_pids;

/* fork and record the pid of the child */
pid_t do_fork(void)
{
	pid_t newpid = fork();
	
	if (newpid) {
		all_pids[num_pids++] = newpid;
	}
	return newpid;
}

/* kill all children 

void kill_all(int sig)
{
	int i;
	for (i=0;i<num_pids;i++) {
		if (all_pids[i] != getpid())
			kill(all_pids[i], sig);
	}
}
* */
#endif
