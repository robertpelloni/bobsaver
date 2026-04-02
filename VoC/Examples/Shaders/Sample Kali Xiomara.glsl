#version 420

// Content under MIT License

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

//Corona effect based on https://www.shadertoy.com/view/4dXGR4

//change to 1.
#define orange_version 0. 

float     inner_radius=.2;
float     outer_radius=.23;
float    zoom=1.8;

float     vol_steps=8.;
float     vol_rot=1.3;
float     vol_fade=.4;

float     surf_scale=2.2;
int     surf_iterations=9;
vec3    surf_param_1=vec3(.8,.9,1.);
float    surf_param_2=1.;
float    surf_param_3=0.;
float     surf_exp=1.6;
float    surf_base_value=.2;
float    surf_intensity=.75;
float    surf_brightness=2.;
float    surf_contrast=2.3;
float     surf_rotation_speed=.15;
float     surf_turbulence_speed=.06;

float     cor_size=.65;
float     cor_offset=.005;
int     cor_iterations=3;
float     cor_iteration_fade=0.;
float     cor_param_1=.12;
float     cor_param_2=.4;
float     cor_exp_1=1.3;
float     cor_exp_2=1.5;
float     cor_brightness=3.3;
float     cor_speed=.15;
float     cor_speed_vary=.7;

float    glow_intensity=.75;
float     glow_size=.6;

vec3    color_1=normalize((1.-orange_version)+vec3(1.0,0.9,0.5)*sign(orange_version-.5));
vec3    color_2=normalize((1.-orange_version)+vec3(1.0,0.5,0.)*sign(orange_version-.5));
float    color_saturation=.55;
float    color_contrast=1.2;
float    color_brightness=.7;

float rand(vec2 p) {return fract(sin(dot(p,vec2(2132.342,4323.343)))*1325.2158);}

mat3 lookat(vec3 fw,vec3 up){
    fw=normalize(fw);vec3 rt=normalize(cross(fw,normalize(up)));return mat3(rt,cross(rt,fw),fw);
}

float sphere(vec3 p, vec3 rd, float r){
    float b = dot( -p, rd ), i = b*b - dot(p,p) + r*r;
    return i < 0. ?  -1. : b - sqrt(i);
}

mat2 rot(float a) {
    float si = sin(a);
    float co = cos(a);
    return mat2(co,si,-si,co);
}

float snoise(vec3 uv, float res)    // by trisomie21
{
    
    const vec3 s = vec3(1e0, 1e2, 1e4);
    
    uv *= res;
    
    vec3 uv0 = floor(mod(uv, res))*s;
    vec3 uv1 = floor(mod(uv+vec3(1.), res))*s;
    
    vec3 f = fract(uv); f = f*f*(3.0-2.0*f);
    
    vec4 v = vec4(uv0.x+uv0.y+uv0.z, uv1.x+uv0.y+uv0.z,
                    uv0.x+uv1.y+uv0.z, uv1.x+uv1.y+uv0.z);
    
    vec4 r = fract(sin(v*1e-3)*1e5);
    float r0 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
    
    r = fract(sin((v + uv1.z - uv0.z)*1e-3)*1e5);
    float r1 = mix(mix(r.x, r.y, f.x), mix(r.z, r.w, f.x), f.y);
    
    return mix(r0, r1, f.z)*2.-1.;
}

float kset(vec3 p) {
    p*=surf_scale*(1.+outer_radius);
    p+=.05;
    float m=1000.;
    for (int i=0; i<surf_iterations; i++) {
        float d=dot(p,p);
        p=abs(p)/d*surf_param_2-vec3(surf_param_1);
        m=min(m,abs(d-surf_param_3))*(1.+surf_param_3);
    }
    float c=pow(max(0.,1.-m)/1.,surf_exp);
    c=pow(c,surf_exp)*surf_exp*surf_intensity;
    return c; 
}

float cor(vec2 p) {
    float ti=time*cor_speed*cor_param_1+200.;
    float d=length(p);
    float fad = (exp(-3.4*d)-outer_radius)/(outer_radius+cor_size);
    
    
    float v1 = fad;
    float v2 = fad;
    float angle = atan( p.x, p.y )/6.2832;
    float dist = length(p)*cor_param_1/.69;
    vec3 crd = vec3( angle, dist, ti * .1 );
    float ti2=ti+fad*cor_speed_vary*cor_param_1;
    float t1=abs(snoise(crd+vec3(0.,-ti2*1.,ti2*.1),15.));
    float t2=abs(snoise(crd+vec3(0.,-ti2*.5,ti2*.2),45.));    
    float it=float(cor_iterations);
    float s=1.;
    for( int i=1; i<=cor_iterations; i++ ){
        ti*=1.5;
        float pw = pow(1.5,float(i));
        v1+=snoise(crd+vec3(0.,-ti,ti*.02),(pw*50.*(t1+1.)))/it*s*.15;
        v2+=snoise(crd+vec3(0.,-ti,ti*.02),(pw*50.*(t2+1.)))/it*s*.15;
    }
    
    float co=pow(v1*fad,cor_exp_2)*cor_brightness;
    co+=pow(v2*fad,cor_exp_2)*cor_brightness;
    co*=1.-t1*cor_param_2*(1.-fad*.3);
    return co;
}

float aalias_cor(vec2 p) {
    for (float i=0.; i<8.; i++) {
        
    }
    return 0.;
}

vec3 render(vec2 uv) {
    vec3 ro=vec3(0.,0.,1.);
    ro.xz*=rot(time*surf_rotation_speed);
    vec3 rd=normalize(vec3(uv,.69));
    rd=lookat(-ro,vec3(0.,1.,0.))*rd;
    float tot_dist=outer_radius-inner_radius;
    float st=tot_dist/vol_steps;
    float br=1./vol_steps;
    float tr=time*surf_rotation_speed;
    float tt=time*surf_turbulence_speed;
    float dist=0.;
    float c=0.;
    float dout=step(0.,sphere(ro, rd, outer_radius));
    float d;
    for (float i=0.; i<vol_steps; i++) {
        d=sphere(ro, rd, inner_radius+i*st);
        dist+=st;
        vec3 p = ro+rd*d;
        float a=vol_rot*i+tt;
        p.yz*=rot(a);
        p.xy*=rot(a);
        c+=kset(p)*br*step(0.,d)*max(0.,1.-smoothstep(0.,tot_dist,dist)*vol_fade);
    }
    c+=surf_base_value;    
    vec3 col=1.*mix(color_1, color_2, vec3(c))*dout*c;
    inner_radius*=.69;
    outer_radius*=.69;
    glow_size*=.69;
    cor_size*=.69;
    float cor=cor(uv);
    float r1=inner_radius;
    float r2=outer_radius;
    float l=smoothstep(r1-cor_offset,r2, length(uv));
    float rt=outer_radius+glow_size;
    float sw=1.-smoothstep(0.,rt,length(uv));
    col=min(vec3(5.),pow(col,vec3(surf_contrast))*surf_brightness*surf_contrast);
    col+=cor*color_1*l+sw*color_2*glow_intensity;
    col=mix(vec3(length(col)), col, color_saturation)*color_brightness;
    return pow(col,vec3(color_contrast));
}

void mainmain( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / resolution.xy-.5;
    uv.x*=resolution.x/resolution.y;
    vec3 col = render(uv/zoom);
    col=pow(col,vec3(1.5))*vec3(1.2,1.,1.);

    fragColor = vec4(col,1.0);
}

void main() {
    vec4 fragColor;
    mainmain(fragColor, gl_FragCoord.xy);
    glFragColor=fragColor;
}

