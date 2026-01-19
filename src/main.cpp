#include <cstdlib>
#include <iostream>
#include <fstream>
#include <sstream>
#include <libssh/libssh.h>
#include <string>

const char *CAM_IP = "192.168.1.10";
const char *USER = "root";
const char *PASS = "root1234"; 

void check_error(ssh_session session, const std::string &msg) {
    std::cerr << "Error during " << msg << ": " << ssh_get_error(session) << std::endl;
    ssh_disconnect(session);
    ssh_free(session);
    exit(1);
}

std::string load_config_from_file(const std::string& filename) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "can't find file " << filename << std::endl;
        exit(1);
    }
    std::stringstream buffer;
    buffer << file.rdbuf();
    return buffer.str();
}

int main() {
    
    if (ssh_init() < 0) {
        std::cerr << "Failed to initialize libssh!" << std::endl;
        return -1;
    }

    std::cout << "Loading config from majestic.yaml..." << std::endl;
    std::string config_content = load_config_from_file("majestic.yaml");

    std::string command = "echo '" + config_content + "' > /etc/majestic.yaml && reboot";

    ssh_session session = ssh_new();
    if (session == NULL) {
        ssh_finalize();
        return -1;
    }

    ssh_options_set(session, SSH_OPTIONS_HOST, CAM_IP);
    ssh_options_set(session, SSH_OPTIONS_USER, USER);
    
    int strict_host_check = 0; 
    ssh_options_set(session, SSH_OPTIONS_STRICTHOSTKEYCHECK, &strict_host_check);

    std::cout << "Connecting to " << CAM_IP << "..." << std::endl;
    int rc = ssh_connect(session);
    if (rc != SSH_OK) check_error(session, "connection");

    std::cout << "Authenticating..." << std::endl;
    rc = ssh_userauth_password(session, NULL, PASS);
    if (rc != SSH_AUTH_SUCCESS) check_error(session, "authentication");

    ssh_channel channel = ssh_channel_new(session);
    if (channel == NULL) check_error(session, "channel creation");
    
    rc = ssh_channel_open_session(channel);
    if (rc != SSH_OK) check_error(session, "channel opening");

    std::cout << "Uploading config and restarting service..." << std::endl;
    rc = ssh_channel_request_exec(channel, command.c_str());
    if (rc != SSH_OK) check_error(session, "execution");

    std::cout << "Success! Check your stream on 192.168.1.20" << std::endl;

    ssh_channel_close(channel);
    ssh_channel_free(channel);
    ssh_disconnect(session);
    ssh_free(session);
    ssh_finalize();

    return 0;
}
