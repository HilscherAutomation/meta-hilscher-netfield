#!/usr/bin/env python3

import base64
from flask import Flask, jsonify, request
import glob
import importlib
import json
import re
import os

REQUEST_FILTER_DIR="/etc/docker/filter/*"

application = app = Flask(__name__)
#app.debug = True

def import_path(path):
    module_name = os.path.basename(path).replace('-', '_')
    spec = importlib.util.spec_from_loader(
        module_name,
        importlib.machinery.SourceFileLoader(module_name, path)
    )
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    #sys.modules[module_name] = module
    return module

def auth(data):
    uri = data['RequestUri']
    method = data['RequestMethod']
    app.logger.debug("Incoming request %r", data)

    ret = True
    msg = "Success"
    error = ""

    for filename in sorted(glob.glob(REQUEST_FILTER_DIR)):
        if os.path.isfile(filename):
            module = import_path(filename)
            try:
                _tmpret, _tmpmsg, _tmperror = module.filter_request(data)
                if _tmpret is False:
                    ret = _tmpret
                    msg = _tmpmsg
                    error = _tmperror
                    break
            except AttributeError as e:
                print(e)
                pass
            except Exception as e:
                ret = False
                msg = str(e)
                error = msg
                break

    app.logger.debug("Returning %r %r %r" % (ret, msg, error))

    return ret, msg, error

@app.route("/Plugin.Activate", methods=['POST'])
def activate():
    return jsonify({'Implements': ['authz']})


@app.route("/AuthZPlugin.AuthZReq", methods=['POST'])
def authz_request():
    plugin_request = json.loads(request.data)
    app.logger.info("request: %r", plugin_request)

    allow, msg, error = auth(plugin_request)

    response = {"Allow": allow,
                "Msg":   msg,
                "Err":   error}

    return jsonify(**response)


@app.route("/AuthZPlugin.AuthZRes", methods=['POST'])
def authz_response():
    plugin_response = json.loads(request.data)
    uri = plugin_response['RequestUri']

    return jsonify(Allow=True)


if __name__ == "__main__":
    app.run()
