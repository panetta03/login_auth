import random, string

# Function to generate a nonce (random string)
def generate_nonce(length=16):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))