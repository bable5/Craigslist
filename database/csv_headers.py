import string
import sys


def read_headers(inputFile) :
    with open(inputFile, 'r') as f:
        header = f.readline()
        header = header.strip()
        elems = header.split(",")
        django_elem_decl = "$field_name = $data_type"
        for e in elems:
            #Assume every header column name is in quotes.
            print( string.Template(django_elem_decl).substitute
                    ({'field_name': e[1:-1], 'data_type':"models.CharField(max_length=None)"} ))

def main():
    if len(sys.argv) >= 2:
        read_headers(sys.argv[1])
    else:
        show_help()

def show_help():
    msg = """
Usage: python csv_headers.py <csv_file>
"""
    print(msg)


if __name__ == "__main__":
    main()
