//+------------------------------------------------------------------+
//| Logger.mqh                                                        |
//| Lightweight leveled logger. Wraps Print() so verbosity and        |
//| formatting are controlled from one place instead of scattering    |
//| raw Print() calls across every module.                            |
//+------------------------------------------------------------------+
#property strict

enum LogLevel
{
   LOG_DEBUG = 0,
   LOG_INFO  = 1,
   LOG_WARN  = 2,
   LOG_ERROR = 3
};

class CLogger
{
private:
   string   m_prefix;
   LogLevel m_minLevel;

   void Write(LogLevel level, string levelTag, string message)
   {
      if(level < m_minLevel)
         return;

      PrintFormat("[%s][%s] %s", m_prefix, levelTag, message);
   }

public:
   /// @param prefix   Tag shown on every log line (e.g. EA name).
   /// @param minLevel Minimum level that gets printed (default: LOG_INFO).
   CLogger(string prefix, LogLevel minLevel = LOG_INFO)
   {
      m_prefix   = prefix;
      m_minLevel = minLevel;
   }

   void Debug(string message) { Write(LOG_DEBUG, "DEBUG", message); }
   void Info(string message)  { Write(LOG_INFO,  "INFO",  message); }
   void Warn(string message)  { Write(LOG_WARN,  "WARN",  message); }
   void Error(string message) { Write(LOG_ERROR, "ERROR", message); }
};
//+------------------------------------------------------------------+
