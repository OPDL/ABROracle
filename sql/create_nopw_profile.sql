CREATE PROFILE "APP_NO_EXPIRE_PW"
LIMIT
COMPOSITE_LIMIT UNLIMITED
SESSIONS_PER_USER UNLIMITED
CPU_PER_SESSION UNLIMITED
CPU_PER_CALL UNLIMITED
LOGICAL_READS_PER_SESSION UNLIMITED
LOGICAL_READS_PER_CALL UNLIMITED
IDLE_TIME UNLIMITED
CONNECT_TIME UNLIMITED
PRIVATE_SGA UNLIMITED
FAILED_LOGIN_ATTEMPTS 1000
PASSWORD_LIFE_TIME UNLIMITED
PASSWORD_REUSE_TIME UNLIMITED
PASSWORD_REUSE_MAX UNLIMITED
PASSWORD_VERIFY_FUNCTION NULL
PASSWORD_LOCK_TIME 86400/86400
PASSWORD_GRACE_TIME 604800/86400
;

