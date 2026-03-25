import { createClient } from "@supabase/supabase-js";

export const supabase = createClient(
  "https://lombvuwhcxeiveftglur.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxvbWJ2dXdoY3hlaXZlZnRnbHVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzMDAwNTMsImV4cCI6MjA4OTg3NjA1M30.hFFw0pSW1SiVp_fcS6H0qmIbkEFSDm3FkIoAsyX_Eac"
);
