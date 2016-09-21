
; First, checking the dark frames
PRO CHECKDARK
   COMMON share,setting
   loadconfig
   
   file=['HP071012NoOverlap-984-984-gc.fits',$
         'HP071012NoOverlap-984-808-gc.fits']
   
   ;for i=0,n_elements(file)-1 do begin 
    for i=0,0 do begin   
      loadgcube,setting.sdarkpath+file[i],im77, im52, im54, im60, hdr
      ;help,im77
      
      d1=fltarr(16*16)
      d2=fltarr(16*16)
      d3=fltarr(16*16)
      d4=fltarr(16*16)
      k=0
      for x=0, 15 do begin
         for y=0, 15 do begin
            a1=reform(im77[x,y,*])
            a2=reform(im52[x,y,*])
            a3=reform(im54[x,y,*])
            a4=reform(im60[x,y,*])
            ind1=where(abs(a1-median(a1)) le 3*meddev(a1) )
            ind2=where(abs(a2-median(a2)) le 3*meddev(a2) )
            ind3=where(abs(a3-median(a3)) le 3*meddev(a3) )
            ind4=where(abs(a4-median(a4)) le 3*meddev(a4) )
            d1[k]=meddev(a1[ind1])
            d2[k]=meddev(a2[ind2])
            d3[k]=meddev(a3[ind3])
            d4[k]=meddev(a4[ind4])
            
            k=k+1
         endfor
      endfor
      plot,d1
      oplot,d2,color=32768
      oplot,d3,color=255
      oplot,d4,color=65535
   endfor
;    for i=0,1614 do begin
;       med=median(im[0,0,i])
;       meddev=median(abs(im[*,*,i]-med))/0.674433
;       print,med
;    endfor
   

END

PRO CHECKCUBE
   COMMON share,setting
   loadconfig
   
   file=['903963g.fits',$
          '903749g.fits',$
          '887131g.fits']
   
   ;for i=0,n_elements(file)-1 do begin 
    for i=2,2 do begin   
      loadgcube,setting.cubepath+file[i],im77, im52, im54, im60, hdr
      ;help,im77
      
      d1=fltarr(14*14)
      d2=fltarr(14*14)
      d3=fltarr(14*14)
      d4=fltarr(14*14)
      k=0
      for x=0, 13 do begin
         for y=0, 13 do begin
            a1=reform(im77[x,y,*])
            a2=reform(im52[x,y,*])
            a3=reform(im54[x,y,*])
            a4=reform(im60[x,y,*])
;             ind1=where(abs(a1-median(a1)) le 3*meddev(a1) )
;             ind2=where(abs(a2-median(a2)) le 3*meddev(a2) )
;             ind3=where(abs(a3-median(a3)) le 3*meddev(a3) )
;             ind4=where(abs(a4-median(a4)) le 3*meddev(a4) )
            ind1=where(a1 ne 0)
            ind2=where(a1 ne 0)
            ind3=where(a1 ne 0)
            ind4=where(a1 ne 0)
            d1[k]=meddev(a1[ind1])
            d2[k]=meddev(a2[ind2])
            d3[k]=meddev(a3[ind3])
            d4[k]=meddev(a4[ind4])
            
            k=k+1
         endfor
      endfor
      plot,d1,yrange=[0,100]
      oplot,d2,color=32768
      oplot,d3,color=255
      oplot,d4,color=65535
   endfor
;    for i=0,1614 do begin
;       med=median(im[0,0,i])
;       meddev=median(abs(im[*,*,i]-med))/0.674433
;       print,med
;    endfor
   

END

FUNCTION MEDDEV, array
   
   med=median(array)
   ;for i=0,n_elements(arrays)-1 do begin
      meddev=median(abs(array-med))/0.674433
   ;endfor
   return, meddev
END