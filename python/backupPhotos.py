import sys
import os
import curses
import time

def main(stdscr):
    curses.init_pair(1, curses.COLOR_RED, curses.COLOR_BLACK)
    current = os.getcwd()

    stdscr.addstr(0,2, 'super cool')
    stdscr.refresh()

    for i in range(101):
        time.sleep(0.1)
        # sys.stdout.write("\r%d%%" % i)
        stdscr.addstr(0, 2, "\r%d%%" % i)
        # sys.stdout.flush()
        showProgress(stdscr, i, 100)
        stdscr.refresh()
    stdscr.getkey()


def showProgress(stdscr, value, total):
    stdscr.addstr(2, 2, '[' + '#'*int(round(((20/total)*value))))
    stdscr.addstr(2, 11, '%d%%' % int(round(value/total * 100)), curses.color_pair(1))
    stdscr.addstr(2, 23, ']')

curses.wrapper(main)

