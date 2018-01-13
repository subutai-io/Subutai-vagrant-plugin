module SubutaiCommands
    UPDATE = "sudo /snap/bin/subutai update"
    LOG    = "sudo /snap/bin/subutai log"
end

module SubutaiAPI
    TOKEN = "https://localhost:9999/rest/v1/identity/gettoken"
    REGISTER_HUB = "https://localhost:9999/rest/v1/hub/register?sptoken="
end