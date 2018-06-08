# -*- coding: utf-8 -*-
"""
Created on Thu Jun  7 18:33:26 2018

@author: alecwong
"""

#%%

import os

#%% 

#%%
# Import two classes from the boxsdk module - Client and OAuth2
from boxsdk import Client, OAuth2

# Define client ID, client secret, and developer token.
CLIENT_ID = None
CLIENT_SECRET = None
ACCESS_TOKEN = None

#%% 

# Read app info from text file
with open('app.cfg', 'r') as app_cfg:
    CLIENT_ID = app_cfg.readline()
    CLIENT_SECRET = app_cfg.readline()
    ACCESS_TOKEN = app_cfg.readline()
    
#%% 
    
from boxsdk.network.default_network import DefaultNetwork
from pprint import pformat

class LoggingNetwork(DefaultNetwork):
    def request(self, method, url, access_token, **kwargs):
        """ Base class override. Pretty-prints outgoing requests and incoming responses. """
        print('\x1b[36m{} {} {}\x1b[0m'.format(method, url, pformat(kwargs)))
        response = super(LoggingNetwork, self).request(
            method, url, access_token, **kwargs
        )
        if response.ok:
            print('\x1b[32m{}\x1b[0m'.format(response.content))
        else:
            print('\x1b[31m{}\n{}\n{}\x1b[0m'.format(
                response.status_code,
                response.headers,
                pformat(response.content),
            ))
        return response
    
#%% 

redirect_uri = 'http://127.0.0.1:5000/return'
 
oauth2 = OAuth2(CLIENT_ID, CLIENT_SECRET)

csrf_token = ''

global csrf_token
auth_url, csrf_token = oauth2.get_authorization_url(redirect_url = redirect_uri)


access_token, refresh_token = oauth2.authenticate(auth_code = )

# Create the authenticated client
# client = Client(oauth2, LoggingNetwork())
client = Client(oauth = oauth2)

#%% 

# Get information about the logged in user (that's whoever owns the developer token)
my = client.user(user_id='me').get()
print (my.name)
print (my.login)
print (my.avatar_url)


root_folder = client.folder('0')
root_folder_with_info = root_folder.get()

# Save time and bandwidth by only asking for the folder owner
root_folder_with_limited_info = root_folder.get(fields=['owned_by'])

#%% 
testpath = os.path.abspath('localOutput/')
testfile_names = os.listdir('localOutput/')[0:10]
for name in testfile_names:
    box_file = client.folder('48978104905').upload(file_path = testpath + "\\" + name)

#%%





