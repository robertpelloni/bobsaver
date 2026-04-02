    vec3 dir = normalize(org - camera_pos);
    vec4 col = vec4(0.0, 0.0, 0.0, 1.0);
    vec3 p = org.xyz;
    float d, g;
    
    for (int i = 0; i < 256; i++) {
        d = scene(p.xyz) * 1.0;
        p = p + d * dir;
    }
    
    
    vec3 n=getN(p);
    //float a=AO(p,n);
	float a=1;
    vec3 s=vec3(0,0,0);
    vec3 lp[3],lc[3];
	//light positions
    lp[0]=vec3(-15,30,-40);
    lp[1]=vec3(-15,-10,-300);
    lp[2]=vec3(-15,-20,-50);  
    //lp[0]=vec3(eyez*2.0,-eyez,eyez*2.0);
    //lp[1]=vec3(-eyez,-eyez,-eyez);
    //lp[2]=vec3(-eyez*3.0,-eyez*2.0,-eyez);  
	
    //light colors
	lc[0]=vec3(1.0,0.0,0.0);  
    lc[1]=vec3(1.0,1.0,1.0);  
    lc[2]=vec3(0.0,0.0,1.0);  
    
    for(int i=0;i<3;i++){
        vec3 l,lv;
        lv=lp[i]-p;
        l=normalize(lv);
        vec3 r = reflect(-l, n);
        vec3 v = normalize(camera_pos - p);
        g=length(lv);
        g = (max(0.0,dot(l,n)) + pow(max(0.0, dot(r, v)), 2.0))/(g)*eyez;
        s+=g*lc[i];
    }
    float fg=min(1.0,20.0/length(p-org));
    col = vec4(s*a,1)*fg*fg;
    gl_FragColor = col;
}
