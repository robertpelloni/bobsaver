#version 420

// Ha en fin kväll Kai!

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 orb = vec4(1000);

float de(vec3 p, float s){
    float r =0.,power = 8.,dr = 1.;
    vec3 z = p;
    for(int i=0;i<10;i++){
        r = length(z);        
        if(r > 3.) break;
        
        float theta = acos(z.z / r) ;// fract(time/20.) ;
        float phi = atan(z.y,z.x);
        
        dr = pow(r,power-1.)*power*dr+1.;
        
        float zr =  pow(r,power);
        
        
        theta = theta * power;
        phi = phi*power;
        z =  zr*vec3(sin(theta) * cos(phi),sin(phi) * sin(theta),cos(theta)) ;
        z += p;
        orb = min( orb, vec4(abs(p),zr) );
            
    }
    
    return (.5 * log(r) * r / dr); 
    
}

vec3 normal( in vec3 pos, in float t, in float s )
{
    float pre = 0.001 * t;
    vec2 e = vec2(1.0,-1.0)*pre;
    return normalize( e.xyy*de( pos + e.xyy,s ) + 
                      e.yyx*de( pos + e.yyx,s ) + 
                      e.yxy*de( pos + e.yxy,s ) + 
                      e.xxx*de( pos + e.xxx,s) );
}

float raymarch(in vec3 from, in vec3 dir,float s) {

    float maxd = 30.0;
    float t = 0.001;
    for( int i=0; i<128; i++ )
    {
    float precis = 0.001 * t;
        
       float h = de( from+dir*t,s );
        if( h<precis||t>maxd ) break;
        t += h;
    }

    if( t>maxd ) t=-1.0;
    return t;
}

vec3 postProcess(vec3 color){
    color*=vec3(1.,.94,.87);
    color=pow(color,vec3(1.3));
    color=mix(vec3(length(color)),color,.85)*0.95;
    return color;
}

vec3  light1 = vec3(  0.577, 0.577, -0.577 );
vec3  light2 = vec3( -0.707, 0.500,  0.707 );

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),1.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
        return mat3( cu, cv, cw );
}

void main(){

    float anim = 0.5*smoothstep( -0.3, 0.6, cos(1.10*time) );
    
    vec2 uv = (-resolution.xy + 2.0*gl_FragCoord.xy)/ resolution.y;

    
    float tm = 0.3*time;
    
    vec3 ro =  vec3( 0.8*cos(0.1+.33*tm), 0.4 + 0.30*cos(0.37*tm), 2.8*cos(1.1+0.35*tm) );
    
    vec3 ta = vec3(-0.0, -.0, -0.0);
    
     
    mat3 ca = setCamera( ro, ta, anim );
     
       vec3 rd = ca * normalize( vec3(uv.xy,1.5));
    
    float t = raymarch(ro,rd,time);
    
    vec3 rgb = vec3(1.0);
    vec3 col = vec3(0.0);
   
    if(t > 0.0){
    
    vec4 tra = orb;
        vec3 pos = ro + t*rd;
        vec3 nor = normal( pos, t, 0.1 );
        
        float key = clamp( dot( light1, nor ), 0.0, 1.0 );
        float bac = clamp( 0.2 + 0.8*dot( light2, nor ), 0.0, 1.0 );
        float amb = (1.+0.4*nor.y);
        float ao = pow( clamp(tra.w*2.0,0.0,1.0), 1.2 );
    
        

        vec3 brdf  = 1.0*vec3(0.40,0.40,0.40)*amb*ao;
        brdf += 1.0*vec3(1.00,1.00,1.00)*key*ao;
        brdf += 1.0*vec3(0.40,0.40,0.40)*bac*ao;

            rgb = mix( rgb, vec3(1.0,0.80,0.2), clamp(6.0*tra.y,0.0,1.0) );
            rgb = mix( rgb, vec3(1.0,0.55,0.0), pow(clamp(1.0-2.0*tra.z,0.0,1.0),8.0) );

          col = rgb*brdf*exp(-0.2*t);
        
        
      col = sqrt(col);
        
    }else{
        col = vec3(0.);
    }
    
    
    glFragColor = vec4(  postProcess(col)  ,1.0);

    
}
