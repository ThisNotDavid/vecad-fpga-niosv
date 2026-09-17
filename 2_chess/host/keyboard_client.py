"""Keyboard-only controller. All chess logic and graphics run on the FPGA."""
import argparse
import queue
import threading
import time
import tkinter as tk
from tkinter import messagebox
from jtag_backend import JtagLink

KEYS={'Up':b'w','Down':b's','Left':b'a','Right':b'd',
    'w':b'w','s':b's','a':b'a','d':b'd','Return':b'e','space':b'e','Escape':b'x',
    '1':b'1','2':b'2','3':b'3','4':b'4'}
MOVEMENT={b'w',b'a',b's',b'd'}

def worker(commands,events,stop,args):
    link=None
    try:
        events.put(('status','Connecting to FPGA...'))
        link=JtagLink(args.quartus_root,args.cable,args.device,args.instance)
        # Discard old echoes, then verify the programmed design using a no-op.
        end=time.monotonic()+0.2
        while time.monotonic()<end: link.read();time.sleep(0.01)
        link.exchange(b'?')
        events.put(('ready','Connected - click this window, then use your keyboard.'))
        while not stop.is_set():
            try: command=commands.get(timeout=0.1)
            except queue.Empty: continue
            link.exchange(command)
            events.put(('ack',command.decode()))
    except Exception as exc:
        events.put(('error',str(exc)))
    finally:
        if link: link.close()
        events.put(('closed',''))

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--quartus-root',default='C:/altera_lite/25.1std')
    parser.add_argument('--cable',default=None)
    parser.add_argument('--device',type=int,default=0,help='JTAG Atlantic device index; 0 auto-detects')
    parser.add_argument('--instance',type=int,default=0)
    parser.add_argument('--probe',action='store_true',help='Open the link, verify a no-op echo, and exit')
    args=parser.parse_args()
    if args.probe:
        link=JtagLink(args.quartus_root,args.cable,args.device,args.instance)
        try: link.exchange(b'?');print('FPGA command/echo PASSED')
        finally: link.close()
        return
    root=tk.Tk();root.title('VECAD Chess - Keyboard Controller');root.geometry('640x410')
    root.configure(bg='#262522')
    status=tk.StringVar(value='Disconnected');details=tk.StringVar(value='The game appears on your VGA monitor.')
    tk.Label(root,text='VECAD CHESS',font=('Segoe UI',25,'bold'),bg='#262522',fg='#e8eadf').pack(pady=(24,12))
    tk.Label(root,text='ARROWS / WASD     Move cursor\nENTER / SPACE      Select or move\nESC                         Cancel selection\n1 / 2 / 3 / 4              Promote: Q / R / B / N\nF2                           New game',
        justify='left',font=('Consolas',13),bg='#262522',fg='#ddddcc').pack(pady=12)
    tk.Label(root,textvariable=status,wraplength=590,bg='#262522',fg='#b8d889',font=('Segoe UI',11)).pack(pady=12)
    tk.Label(root,textvariable=details,bg='#262522',fg='#aaaaaa').pack()
    commands=queue.Queue(maxsize=8); events=queue.Queue(); stop=threading.Event()
    state={'ready':False,'thread':None,'pressed':set(),'times':{},'acks':0}
    def connect():
        if state['thread'] and state['thread'].is_alive(): return
        while not commands.empty(): commands.get_nowait()
        state['ready']=False;stop.clear()
        state['thread']=threading.Thread(target=worker,args=(commands,events,stop,args),daemon=True)
        state['thread'].start()
    def send(command):
        if state['ready']:
            try: commands.put_nowait(command)
            except queue.Full: details.set('Input queue full; wait for the board to catch up.')
    def key(event):
        name=event.keysym; command=KEYS.get(name)
        now=time.monotonic()
        if name=='F2' and name not in state['pressed']:
            state['pressed'].add(name)
            if state['ready'] and messagebox.askyesno('New game','Restart the current chess game?'): send(b'!')
            state['pressed'].clear();return 'break'
        if command:
            if command in MOVEMENT:
                if now-state['times'].get(name,0)>=0.12: send(command);state['times'][name]=now
            elif name not in state['pressed']: send(command)
            state['pressed'].add(name)
        return 'break'
    def release(event): state['pressed'].discard(event.keysym)
    root.bind('<KeyPress>',key);root.bind('<KeyRelease>',release)
    root.bind('<FocusOut>',lambda event:state['pressed'].clear())
    def poll():
        while not events.empty():
            kind,text=events.get_nowait()
            if kind=='ready': state['ready']=True;status.set(text)
            elif kind in ('status','error'): status.set(text);state['ready']=False
            elif kind=='ack': state['acks']+=1;details.set(f'FPGA acknowledged {state["acks"]} commands. Last: {text}')
            elif kind=='closed': state['ready']=False
        root.after(40,poll)
    tk.Button(root,text='Connect / Reconnect',command=connect,font=('Segoe UI',11)).pack(pady=15)
    def close(): stop.set();root.destroy()
    root.protocol('WM_DELETE_WINDOW',close)
    poll();connect();root.mainloop()

if __name__=='__main__': main()
