clear

! IEEE 4-bus test case   Y-Y Stepdown Balanced
! Based on script developed by Alan Dunn and Steve Sparling

new circuit.4BusYYbal basekV=12.47 phases=3 
! **** HAVE TO STIFFEN THE SOURCE UP A LITTLE; THE TEST CASE ASSUMES AN INFINITE BUS
~ mvasc3=200000 200000

set earthmodel=carson

! **** DEFINE WIRE DATA 
new wiredata.conductor Runits=mi Rac=0.306 GMRunits=ft GMRac=0.0244  Radunits=in Diam=0.721 
new wiredata.neutral   Runits=mi Rac=0.592 GMRunits=ft GMRac=0.00814 Radunits=in Diam=0.563 

! **** DEFINE LINE GEOMETRY; REDUCE OUT THE NEUTRAL
new linegeometry.4wire nconds=4 nphases=3 reduce=yes 
~ cond=1 wire=conductor units=ft x=-4   h=28 
~ cond=2 wire=conductor units=ft x=-1.5 h=28 
~ cond=3 wire=conductor units=ft x=3    h=28 
~ cond=4 wire=neutral   units=ft x=0    h=24 

! **** 3-PHASE STEP-DOWN TRANSFORMER 12.47/4.16 KV Y-Y
new transformer.t1 xhl=6 sub=y
~ wdg=1 bus=sourcebus conn=wye kV=12.47 kVA=6000 %r=0.5 
~ wdg=2 bus=n1 conn=wye kV=4.16  kVA=6000 %r=0.5 


! **** 12.47 KV LINE
new line.line1 geometry=4wire length=2000 units=ft bus1=n1 bus2=n2

! **** 3-PHASE STEP-DOWN TRANSFORMER 12.47/4.16 KV Y-Y
!new transformer.t1 xhl=6
!~ wdg=1 bus=n2 conn=wye kV=12.47 kVA=6000 %r=0.5 
!~ wdg=2 bus=n3 conn=wye kV=4.16  kVA=6000 %r=0.5 

! **** 4.16 KV LINE
new line.lineNew bus1=n2 bus2=n3 geometry=4wire length=2500 units=ft 

! **** 4.16 KV LINE
new line.line2 bus1=n3 bus2=n4 geometry=4wire length=2500 units=ft  

! **** WYE-CONNECTED 4.16 KV LOAD
new load.load1 phases=3 bus1=n4 conn=wye kV=4.16 kW=5400 pf=0.9  model=1
! **** HAVE TO ALLOW P, Q TO REMAIN CONSTANT TO ABOUT .79 PU -- THIS IS ASSUMED IN TEST CASE
! **** DEFAULT IN DSS IS .95, BELOW WHICH IT REVERTS TO LINEAR MODEL
~ vminpu=0.75    ! model will remain const p,q down to 0.75 pu voltage   

new pvsystem.pv1 phases=3 bus1=n4 conn=wye kV=4.16 pmpp=5000 kva=5500 effcurve=myeff P-Tcurve=mypvst
new xycurve.vvc1 npts=6 xarray=[.5 .95 .98 1.02 1.05 1.5] yarray=[1 1 0 0 -1 -1]
new xycurve.myeff npts=4 xarray=[.1 .2 .4 1] yarray=[1 1 1 1]
new xycurve.mypvst npts=4 xarray=[0 25 75 100] yarray=[1 1 1 1]
new invcontrol.inv1 mode=voltvar voltage_curvex_ref=rated vvc_curve1=vvc1 deltaQ_factor=.1

set voltagebases=[12.47, 4.16] 
calcvoltagebases     ! **** let DSS compute voltage bases
set maxiterations=1000
set maxcontroliter=1000
solve


dump line.line2 debug