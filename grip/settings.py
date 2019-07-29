#!/usr/bin/env python3

import os
import configparser

config = configparser.ConfigParser()

user_config_file = os.path.join(os.path.dirname(__file__), 'user.ini')
config.read(user_config_file)

USERNAME = config['github']['username']
PASSWORD = config['github']['personal_access_token']
