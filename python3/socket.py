import os
import threading as t
from multiprocessing import Process
import vim

def remove_align(s):
    return s.replace("%=", "")

class Socket:
    def __init__(self):
        self.split = vim.eval("g:tpipeline_split")
        self.default_color = vim.eval("s:default_color")
        tmux_s = os.environ["TMUX"]
        tmux_split = tmux_s.split(",")
        # for example /tmp/tmux-1000/default-$0-vimbridge
        self.left_filepath = tmux_split[0] + "-$" + tmux_split[-1] + "-vimbridge"
        self.right_filepath = self.left_filepath + "-R"
        self.socket_write_count = 0
        self.socket_rotate_threshold = 128
        self.last_written_line = ""

    def update(self, l):
        write_mode = "a"
        self.socket_write_count += 1
        # rotate the file when it gets too large
        if self.socket_write_count > self.socket_rotate_threshold:
            write_mode = "w"
            self.socket_write_count = 0
    
        # append default color
        l = self.default_color + l
    
        if self.split:
            split_point = l.find("%=")
            left_line = l
            right_line = ""
            if split_point >= 0:
                left_line = l[0:split_point]
                right_line = self.default_color + remove_align(l[split_point + 2:])
    
            # TODO: Optimize IO perf
            r_file = open(self.right_filepath, write_mode)
            r_file.write(right_line + "\n")
            r_file.close()
            self.last_written_line = left_line
        else:
            self.last_written_line = remove_align(l)
    
        l_file = open(self.left_filepath, write_mode)
        l_file.write(self.last_written_line + "\n")
        l_file.close()
        os.system("tmux refresh-client -S")


s = Socket()
def write():
    l = vim.eval("s:last_statusline")
    x = Process(target=Socket.update, args=(s, l,))
    x.start()
