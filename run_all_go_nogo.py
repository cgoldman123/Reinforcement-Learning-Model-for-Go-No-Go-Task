import sys, os, re, subprocess

subject_list_path = '/media/labs/rsmith/lab-members/cgoldman/go_no_go/subject_names_go_nogo.csv'
input_directory = '/media/labs/rsmith/lab-members/cgoldman/go_no_go/COBRE_GNGB_data'
results = sys.argv[1]

if not os.path.exists(results):
    os.makedirs(results)
    print(f"Created results directory {results}")

if not os.path.exists(f"{results}/logs"):
    os.makedirs(f"{results}/logs")
    print(f"Created results-logs directory {results}/logs")

subjects = []
with open(subject_list_path) as infile:
    for line in infile:
        if 'x' not in line:
            subjects.append(line.strip())

ssub_path = '/media/labs/rsmith/lab-members/cgoldman/go_no_go/run_go_nogo.ssub'

for subject in subjects:
    stdout_name = f"{results}/logs/{subject}-%J.stdout"
    stderr_name = f"{results}/logs/{subject}-%J.stderr"

    jobname = f'gonogo-fit-{subject}'
    os.system(f"sbatch -J {jobname} -o {stdout_name} -e {stderr_name} {ssub_path} {subject} {input_directory} {results}")

    print(f"SUBMITTED JOB [{jobname}]")
  

    ###python3 run_all_go_nogo.py /media/labs/rsmith/lab-members/cgoldman/go_no_go/fits