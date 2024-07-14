import time, psutil, sys, os, logging, subprocess, json
from PIL import Image, ImageDraw, ImageFont

# Add SSD1305 display library path if necessary
libdir = os.path.join(os.path.dirname(os.path.dirname(os.path.realpath(__file__))), 'drive')
if os.path.exists(libdir):
    sys.path.append(libdir)

from lcdlib import SSD1305

# Check eth0 current connection status
def get_eth0_status():
    interfaces = psutil.net_if_stats()
    return interfaces.get('eth0', None) and interfaces['eth0'].isup

# Check if eth0 LLDP information exists
def get_eth0_lldp_status():
    try:
        result = subprocess.run(['lldpctl', '-f', 'keyvalue', 'eth0'], capture_output=True, text=True)
        return f"lldp.eth0" in result.stdout
    except FileNotFoundError:
        logging.error("lldpctl command not found. Please ensure lldpd is installed.")
        return False
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        return False

# Pull eth0 LLDP information
def get_eth0_lldp_info():
    try:
        output = json.loads(subprocess.check_output(["lldpctl", "-f", "json", "eth0"]).decode('utf-8'))
        chassis_info = output['lldp']['interface']['eth0']['chassis']
        hostname = list(chassis_info.keys())[0]
        mgmt_ip = chassis_info[hostname]['mgmt-ip']
        port = output['lldp']['interface']['eth0']['port']['id']['value']
        vlan = output['lldp']['interface']['eth0']['vlan']['vlan-id']

        return {
            'hostname': hostname,
            'mgmt_ip': mgmt_ip,
            'port': port,
            'vlan': vlan
        }
    except subprocess.CalledProcessError as e:
        logging.error(f"Command failed with exit code {e.returncode}")
        return None
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}")
        return None

def get_battery_status():
    try:
        output_bytes = subprocess.check_output(
            "echo \"get battery\" | nc -q 0 127.0.0.1 8423 | awk 'BEGIN {FS=\":\"};{print $2}' | sed 's/^[[:space:]]*//'",
            shell=True
        )
        output_str = output_bytes.decode('utf-8').strip()
        return int(float(output_str))
    except (subprocess.CalledProcessError, ValueError) as e:
        logging.error("Failed to get battery status: %s", e)
        return 0

def draw_battery(draw, font, position, level, width, height):
    x, y = position
    draw.rectangle([x, y, x + width, y + height], outline=255, fill=255)
    terminal_width = width // 5
    terminal_height = height // 2
    draw.rectangle([x + width, y + (height - terminal_height) // 2, x + width + terminal_width, y + (height + terminal_height) // 2], outline=255, fill=255)
    filled_width = int((width - 2) * (level / 100))
    draw.rectangle([x + 1, y + 1, x + 1 + filled_width, y + height - 1], outline=000, fill=255)
    draw.text((94, 0), str(level) + "%", font=font, fill=255)

def draw_scrolling_text(draw, font, position, text, width):
    x, y = position
    text_width, _ = draw.textsize(text, font=font)
    if len(text) <= 25:
        draw.rectangle([x, y, x + width, y + 8], outline=0, fill=0)
        draw.text((x, y), text, font=font, fill=255)
    else:
        scroll_position = int(time.time() * 25) % (text_width + width)
        draw.rectangle([x, y, x + width, y + 8], outline=0, fill=0)  # Clear the area
        draw.text((x - scroll_position, y), text, font=font, fill=255)
        draw.text((x - scroll_position + text_width + 25, y), text, font=font, fill=255)

def clear_text(draw):
    draw.rectangle([0, 0, 90, 8], outline=0, fill=0)
    draw.rectangle([0, 8, 128, 16], outline=0, fill=0)
    draw.rectangle([0, 16, 128, 24], outline=0, fill=0)
    draw.rectangle([0, 24, 128, 32], outline=0, fill=0)

def main():
    # Display initialization
    disp = SSD1305.SSD1305()
    disp.Init()
    disp.clear()
    width, height = disp.width, disp.height
    image = Image.new('1', (width, height))
    draw = ImageDraw.Draw(image)
    font = ImageFont.truetype('/network-port-finder/04B_08__.TTF', 8)

    battery_level = get_battery_status()
    battery_position = (width - 12, 0)

    dev = False  # Set to True for development mode
    previous_battery_state = None
    while True:
        try:
            battery_level = get_battery_status()
            if previous_battery_state != battery_level:
                draw.rectangle((0, 0, width, height), outline=0, fill=0)
                draw_battery(draw, font, battery_position, battery_level, width=10, height=5)
            previous_battery_state=battery_level

            if dev:
                port_output = {
                    'hostname': 'dc1-tst-net-sw-005.letsautomateit.com',
                    'mgmt-ip': '222.222.222.222',
                    'port': 'Gi1/0/22',
                    'vlan': "4096"
                }
                draw.text((0, 0), "Dev LLDP Info", font=font, fill=255)
                draw_scrolling_text(draw, font, (0, 8),  'MGMT IP: ' + port_output['mgmt-ip'], width)
                draw_scrolling_text(draw, font, (0, 16), port_output['hostname'], width)
                draw_scrolling_text(draw, font, (0, 24), port_output['port'], width)

                disp.getbuffer(image)
                disp.ShowImage()
                time.sleep(0.1)
            else:
                if not get_eth0_status():
                    clear_text(draw)
                    draw.text((0, 16), "eth0 not connected", font=font, fill=255)
                    disp.getbuffer(image)
                    disp.ShowImage()
                    time.sleep(0.1)
                elif not get_eth0_lldp_status():
                    clear_text(draw)
                    draw.text((0, 8), "No LLDP information", font=font, fill=255)
                    draw.text((0, 16), "available.", font=font, fill=255)
                    disp.getbuffer(image)
                    disp.ShowImage()
                    time.sleep(0.1)
                else:
                    lldp_info = get_eth0_lldp_info()
                    draw.text((0, 0), "LLDP Information", font=font, fill=255)
                    draw_scrolling_text(draw, font, (0, 8), lldp_info.get('mgmt_ip', 'Unknown'), width)
                    draw_scrolling_text(draw, font, (0, 16), lldp_info.get('hostname', 'Unknown'), width)
                    draw_scrolling_text(draw, font, (0, 24), lldp_info.get('port', 'Unknown'), width)
                    disp.getbuffer(image)
                    disp.ShowImage()
                    time.sleep(0.1)
            
        except KeyboardInterrupt:
            break

if __name__ == "__main__":
    main()
