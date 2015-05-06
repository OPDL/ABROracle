sELECT t.*,
       max( Last_Payment_Date ) OVER( partition by Account ) last_dat
  FROM table1 t
