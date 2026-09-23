-- BEGIN GENERATED HAPPYWHEEL SEED
INSERT INTO zha_dan_info (id,type,award,num,petQt,petQtLv,rate,isJinPin,isShow,notice) VALUES
(29001,2,60000,100000,0,0,2500,0,1,'0'),
(29002,2,851,10,0,0,1800,0,1,'0'),
(29003,2,852,5,0,0,1500,0,1,'0'),
(29004,2,853,3,0,0,1200,0,1,'0'),
(29005,2,854,1,0,0,800,0,1,'0'),
(29006,2,613,5,0,0,700,0,1,'0'),
(29007,2,500,1,0,0,600,0,1,'0'),
(29008,2,401,1,0,0,400,0,1,'0'),
(29009,2,402,1,0,0,300,0,1,'0'),
(29010,2,403,1,0,0,200,0,1,'0')
ON CONFLICT(id) DO UPDATE SET
  type=excluded.type, award=excluded.award, num=excluded.num,
  petQt=excluded.petQt, petQtLv=excluded.petQtLv, rate=excluded.rate,
  isJinPin=excluded.isJinPin, isShow=excluded.isShow, notice=excluded.notice;
-- END GENERATED HAPPYWHEEL SEED
