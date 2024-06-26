input_file = 'source/binary_data.txt'
output_file = 'source/memory_init.txt'

with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
    for line in infile:
        binary_value = line.strip()
        outfile.write(f"{binary_value}\n")

print("Memory initialization file created.")
