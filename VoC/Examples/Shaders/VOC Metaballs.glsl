#version 120

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

// metaball by @h013

float metaball(vec3 p, vec4 spr){
	float fv[17];
	fv[0] = length(p - vec3(-3,-2,-1));
	fv[1] = length(p - vec3(-3,-1,1));
	fv[2] = length(p - vec3(-2,-2,0));
	fv[3] = length(p - vec3(-2,3,-3));
	fv[4] = length(p - vec3(-2,3,-2));
	fv[5] = length(p - vec3(-1,-3,1));
	fv[6] = length(p - vec3(-1,-2,2));
	fv[7] = length(p - vec3(-1,-1,-1));
	fv[8] = length(p - vec3(-1,2,-1));
	fv[9] = length(p - vec3(0,-1,1));
	fv[10] = length(p - vec3(0,0,0));
	fv[11] = length(p - vec3(0,1,0));
	fv[12] = length(p - vec3(0,3,-2));
	fv[13] = length(p - vec3(1,0,2));
	fv[14] = length(p - vec3(1,3,-3));
	fv[15] = length(p - vec3(2,1,2));
	fv[16] = length(p - vec3(2,2,3));
	float len = 0.0;
	float fs = 0.2;
	for (int i = 0; i < 17; i ++) {
        len += fs / (fv[i] * fv[i]);
    }
    //len = min(16.0, len);
    len = 1.0 - len;
    return len;
}

mat4 getrotz(float angle) {
    return mat4(cos(angle), -sin(angle), 0.0, 0.0,
                sin(angle),  cos(angle), 0.0, 0.0,
                0.0,         0.0, 1.0, 0.0,
                0.0,         0.0, 0.0, 1.0);
}
mat4 getrotx(float angle) {
    return mat4(       1.0,         0.0, 0.0, 0.0,
                0.0, cos(angle), -sin(angle), 0.0,
                0.0, sin(angle), cos(angle), 0.0,
                0.0, 0.0, 0.0, 1.0);
}

float scene(vec3 p) {
    float angle = time;
    mat4 rotmat = getrotz(angle) * getrotx(angle * 0.5);
    vec4 q = rotmat * vec4(p, 0.0);
    float d = metaball(q.xyz,vec4(0.0, 0.0, 2.0 , 6.0));
    return d;
}

vec3 getN(vec3 p){
    float eps=0.001;
    return normalize(vec3(
        scene(p+vec3(eps,0,0))-scene(p-vec3(eps,0,0)),
        scene(p+vec3(0,eps,0))-scene(p-vec3(0,eps,0)),
        scene(p+vec3(0,0,eps))-scene(p-vec3(0,0,eps))
    ));
}
float AO(vec3 p,vec3 n){
    float dlt=0.5;
    float oc=0.0,d=1.0;
    for(float i=0.0;i<6.;i++){
        oc+=(i*dlt-scene(p+n*i*dlt))/d;
        d*=2.0;
    }
    
    float tmp = 1.0-oc;
    return tmp;
}

void main(void) {
    float aspect = resolution.y / resolution.x;
    float eyez = 20;
    vec3 org = vec3(vec2(0.5, 0.5) - gl_FragCoord.xy / resolution.xy, -20);
    org.y *= aspect;
    vec3 camera_pos = vec3(0.0, 0.0, -21);
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
