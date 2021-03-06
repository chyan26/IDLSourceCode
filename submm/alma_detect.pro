PRO ALMA_DETECT, START_FIELD, END_FIELD, SIGMA, CONFIG
	common share, dataset;, im3
	common share1, im3
	fwhm=[13.5,5.02,2.85]
	sigma=3.0
	start_field=10
	end_field=10
	config=1
	rate=fltarr(5)
	count=fltarr(5)
	count(*)=0
	rate(*)=0 	
	
	dataset='ALMA_sky1_8hr'
	im1='/scr1/'+dataset+'/Fits/alma_'
	im2=['1','11','29','4']
	im3='_030524_'
	im4='.fits'
	s1='/scr1/'+dataset+'/Data/submm_source'
 
	close,1
	openw,1,'/scr1/'+dataset+'/Detect/alma_detecion_'+im2(config-1)+'_'+strmid(strcompress(string(sigma),/remov),0,3)
	for i=start_field, end_field do begin
	 	print,'Now processing image',i

		fitsfile=im1+im2(config-1)+im3+strcompress(string(i),/remov)+im4
		sourcefile=s1+strcompress(string(i),/remov)
		
		read_source,sourcefile,flux,x,y
		im=readfits(fitsfile)
		rms=stddev(im)
		th_image_cont,im,level=[2*rms,3*rms],xrange=[-128,128]$
			,/aspect,yrange=[-128,128],/nobar,ct=3$
			,crange=[0.1*rms,5*rms]
		oplot_source,flux,x,y,sigma,rms

		data=detect_count(im,fwhm(config-1),sigma,rms,i,config)
		if data(0) eq -1 then begin
			print,'No detection'
			rate(0)=n_elements(x)+rate(0)
			ind=where(flux ge sigma*rms,c)
			rate(1)=c+rate(1)
		endif else begin	
			dd=d_rate(flux,x,y,data(0,*),data(1,*),data(2,*),fwhm(config-1),sigma,rms)
			for j=0, n_elements(data(0,*))-1 do begin
				printf,format='(f12.8,f10.4,f10.4,tr4,i3)'$
					,1,data(0,j),-data(1,j)*0.14,data(2,j)*0.14,i
			endfor
			count=dd+count
		endelse
		print,rate	
		print,count
	endfor
	
	count=rate+count
	print,count
	close,1

	openw,1,'/scr1/'+dataset+'/Detect/alma_count_'+im2(config-1)+'_'+strmid(strcompress(string(sigma),/remov),0,3)
	printf,1,'Total No. of source(s) inputed',count(0)
	printf,1,'No. of source(s) with f > 3-sigma:',count(1)
	printf,1,'No. of source(s) detected by FIND:',count(2)
	printf,1,'No. of source(s) f > 3-sigma and detected:',count(3)
	printf,1,'No. of source(s) f < 3-sigma but detected:',count(4)
	close,1	
	

	resetplt,/all

end
 
FUNCTION DETECT_COUNT, IMAGE, FWHM ,SIGMA, RMS, FIELD_NO, CONFIG, DATA
;
;   COUNT
;       Return the detection counts, the first is the expected source
;       number over given sigma. The second is the detected source
;       number using FIND with flux over given sigma.  The last is the
;	number of detected and expected sources.
;
	fwhm=FWHM
	sigma=SIGMA
	im=IMAGE
 

	imm=smooth2(im,fwhm/2)
 	;imm=im
	;th_image_cont,imm,level=[2*rms,3*rms],xrange=[-128,128]$
	;		,/aspect,yrange=[-128,128],/nobar,ct=3$
	;		,crange=[0.1*rms,5*rms]
	auto_find_alma,imm,fwhm,rms,sigma,x_a,y_a,f_a
	;oplot,x_a-128,y_a-128,psym=6

	if keyword_set(x_a) eq 0 then begin
		data=-1
		goto,here
	endif		

	avg_bg, 2, field_no, bg_image, config
	bb=smooth2(bg_image,fwhm/2)

	;bb=bg_image
	auto_find_alma,bb,fwhm,rms/1.5,sigma,x_f,y_f,ff

	
	if keyword_set(x_f) eq 0 then begin
		x_d=x_a
		y_d=y_a
		flux=f_a
	endif else begin	
		reject_false,x_a,y_a,f_a,x_f,y_f,ff,x_d,y_d,flux,rms
	endelse

	if keyword_set(x_d) eq 0 then begin
		data=-1
		goto,here	
	endif else begin
		x_d=x_d-128
		y_d=y_d-128
		oplot,x_d,y_d,psym=5,color=255
		data=fltarr(3,n_elements(x_d))
		data(0,*)=flux
		data(1,*)=x_d
		data(2,*)=y_d
	endelse
	
	here:
	return,data
	
END


FUNCTION D_RATE, FLUX, X, Y, F_D, X_D, Y_D, FWHM, RMS, SIGMA, COUNT
	x=X
	y=Y
	x_d=X_D
	y_d=Y_D
	fwhm=FWHM

	
	dd=0   ;dd gives the detection no. for sources flux > 3-sigma and detected
	nd=0   ;ad gives the detection no. for sources flux < 3-sigma but detected

	index=where(flux ge rms*sigma, c, complement=ind_c) 

	if c ne 0 then begin
		for i=0,n_elements(x_d)-1 do begin
			r=(x(index)-x_d(i))^2+(y(index)-y_d(i))^2
			if min(r) lt fwhm*5 then begin
				dd=dd+1
			endif else begin
				dd=dd+0
			endelse
		endfor
	endif else begin
		dd=dd+0
	endelse
 	
	if ind_c(0) eq -1 then goto, final
	if n_elements(ind_c) ne 0 then begin
		for i=0,n_elements(x_d)-1 do begin
			r=(x(ind_c)-x_d(i))^2+(y(ind_c)-y_d(i))^2
			if min(r) lt fwhm*5 then begin
				nd=nd+1
			endif else begin
				nd=nd+0
			endelse
		endfor
	endif else begin
		nd=nd+0
	endelse
	final: 

 
	
	count=fltarr(5)
	count(0)=n_elements(x)
	count(1)=c
	count(2)=n_elements(x_d)
	count(3)=dd
	count(4)=nd
	return,count

END

PRO READ_SOURCE, FILE, FLUX, X, Y
	file=FILE
	flux=FLUX
	x=X
	y=Y
	data=read_ascii(file)
	if n_elements(data.field1) gt 3 then begin
		flux=reform(data.field1(0,*))
		x=-1*reform(data.field1(1,*))/0.07
		y=reform(data.field1(2,*))/0.07
	endif else begin
		flux=data.field1(0)
		x=-1*data.field1(1)/0.07
		y=data.field1(2)/0.07
	endelse
END

PRO OPLOT_SOURCE, FLUX, X, Y, SIGMA, RMS
	flux=FLUX
	x=X
	y=Y
	sigma=SIGMA
	rms=RMS
	index=INDEX    ; sources where f > given sigma level
	no=NO          ; number of sources where f > given sigma level
	ind_c=IND_C    ; sources where f < given sigma level
	index=where(flux ge sigma*rms, c, complement=ind_c)
 	

	if n_elements(index) eq 1 and index(0) eq -1 then goto, next
	if c ne 1 then begin
		plots,x(index),y(index),psym=6,color=255
	endif else begin
		plots,x(index),y(index),psym=6,color=255
	endelse
 
	next:	
	if ind_c(0) eq -1 then goto,final
	if n_elements(ind_c) ne 1 then begin
		oplot,x(ind_c),y(ind_c),psym=1,color=255
	endif else begin
		plots,x(ind_c),y(ind_c),psym=1,color=255
	endelse
	final:
	no=c
END

PRO AUTO_FIND_ALMA, IM, FWHM,RMS, SIGMA, X, Y, FLUX
	hmin=rms*sigma 
	sharplim=[0.00,1.0]
	roundlim=[0.0,1000.0]
	find,im,x,y,flux,sharp,round,hmin,fwhm,roundlim,sharplim,/silent
END

PRO AVG_BG, BG_FIELD, FIELD, IMAGE, CONFIG
	common share;, dataset, im3
	common share1
	name1='/scr1'+dataset+'/Background/alma_'
	name2=['1','11','29','4']
	name3=im3
	name4='_bg'
	name5='.fits'

	data=fltarr(257,257)

	for i=1,bg_field do begin
		filename=name1+name2(config-1)+im3+strcompress(string(field),/remov)+name4+strcompress(string(i),/remov)+name5
		im=readfits(filename)
		data=im+data
	endfor

	data=data/bg_field		

	image=data

END

PRO REJECT_FALSE, X, Y, F, X_F, Y_F, F_F, X_D, Y_D, FLUX, RMS
	flag=bytarr(n_elements(x))
	flag(*)=1
	for i=0, n_elements(x)-1 do begin
		r=(x(i)-x_f)^2+(y(i)-y_f)^2
		ind=where(r eq min(r))
		if min(r) lt 10 and min(abs(f(i)-f_f(ind))) lt 3*rms then begin	
			flag(i)=0
		endif
	endfor
	
	ind=where(flag eq 1,c)
	if c ne 0 then begin
		x_d=reform(x(ind))
		y_d=reform(y(ind))
		flux=reform(f(ind))
	endif else begin
		goto, out
	endelse
	out:
END
