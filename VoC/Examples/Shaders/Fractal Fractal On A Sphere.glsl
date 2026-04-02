#version 420

// original https://www.shadertoy.com/view/slXfD2

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define AA 2
#define PI 3.14159

const float ct0 =  1./sqrt(2.);
const float g = (1.5-sqrt(2.))/(1.5+sqrt(2.));

vec3 sn(vec3 p)
{
    return vec3(sign(p.x),sign(p.y),sign(p.z));
}
//palette function credit: Inigo Quilez https://iquilezles.org/articles/palettes/
vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 6.28318*(c*t+d) );
}

vec3 color(float m){
    return palette(m/3. + 0.5 ,vec3(0.5),vec3(0.5),vec3(1.0),vec3(0.00, 0.10, 0.20));
}

vec3 map(vec3 pos , float time )
{  
    vec4 res = vec4(vec3(0),1);
    
    float t_ind = -mod(floor(time),3.);

    time = mod(time,1.);
    
    float kt = time;
    time = -time * log(g);
    
    float t = 1.;
    
    vec3 v1 = vec3(1.,0.,0.); vec3 nv1 = v1;
    vec3 v2 = vec3(0.,1.,0.); vec3 nv2 = v2;
    vec3 v3 = vec3(0.,0.,1.); vec3 nv3 = v3;
        
    float col =-2.*t_ind/3.;
    float t1 = 1.;
    float yf = 1.;
    
    for(float i=0.;i<16.;i+=1.){
        v1 = nv1;
        v2 = nv2;
        v3 = nv3;
        
        float phi = atan(dot(pos,v3),dot(pos,v1));
        float theta = atan(length(vec2(dot(pos,v3),dot(pos,v1))),dot(pos,v2));
               
        if(i==0.)t1*=exp(time);
        
        theta = acos( ((t1-1.)+(t1+1.)*cos(theta))/((t1+1.)+(t1-1.)*cos(theta)));
        vec3 pos0 = vec3(sin(theta)*cos(phi),cos(theta),sin(theta)*sin(phi));
        pos = v1*pos0.x + v2*pos0.y + v3*pos0.z;
        
        vec3 spos = sn(pos0);
    
        t1 = g;
        
        if(abs(pos0.y)>ct0){
            col = mod(col+(2.)/3.*spos.y*yf,2.);
            yf *= spos.y;
            if(i==0.){
                if(spos.y>0.)res.w += 1.-kt;
                else res.w += kt;
            }
            else res.w+=1.;
            nv2 *= spos.y;
            res.xyz = color(col);
            continue;
        }

        if(abs(pos0.x)>ct0){
            col = mod(col+(1.)/3.,2.);
            yf = 1.;
            res.xyz = color(col);
            res.w += 1.;
            nv2 = v1*spos.x;
            nv1 = v2;
            nv3 = v3;
            continue;
        }
        if(abs(pos0.z)>ct0){
            col = mod(col + (3.)/3.,2.);
            yf = 1.;
            res.xyz = color(col);
            res.w += 1.;
            nv2 = v3*spos.z;
            nv1 = v1;
            nv3 = v2;
            continue;
        }
        res.xyz = color(col);  
        break;    
    }
    return mix(vec3(0.0),res.xyz,exp(-pow(res.w,2.)/100.));
}

vec3 render(vec3 ro,vec3 rd, float time ,vec2 p )
{ 
    vec3 back = vec3(0.);
    float r = length(p);
    back += exp((-r+1.)*20.)*vec3(0.8); 
    
    vec3 col = back;
    vec4 res = vec4(250.,-10.,0.,0.);
    float t = 200.;
    
    float od = dot(ro,rd);
    if(od<0.){
        float o2 = dot(ro,ro);
        float del = od*od - (o2-1.) ;
        if(del>0.){
            t = -od - sqrt(del);
            col = map(ro + t*rd,time);
        }
    }

    vec3 nor = normalize(ro + t*rd);
       
    col = mix(col , back , clamp(exp((r-0.99)*50.),0.,1.) );

    return vec3( clamp(col,0.0,1.0) );
}

void main(void)
{
    vec3 tot = vec3(0.0);
    float time = time/1.5;

    
    float phi = 4.*PI*mouse.x*resolution.xy.x/resolution.x; //2.*PI*time/3.;
    float theta = PI*clamp(-0.1+1.2*mouse.y*resolution.xy.y/resolution.y,0.,1.);//PI/2. + PI/3.*cos(2.*PI*time/3.);

    vec3 ro = 50.*vec3(sin(theta)*cos(phi),cos(theta),sin(theta)*sin(phi));

    vec3 cw = normalize(-ro);
    vec3 cu = vec3(sin(phi),0.,-cos(phi) );
    vec3 cv = ( cross(cu,cw) );

    mat3 ca = mat3(cu*0.2, cv*0.2, cw );

    vec3 rd = ca * normalize( vec3(0.,0.,1.) );     

    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {

        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (2.0*(gl_FragCoord.xy+o)-resolution.xy)/resolution.y*1.2;
        vec3 pp = ca * vec3(p,0.);
        vec3 col = render( ro + pp*5., rd, time,p );
        tot+=col;
           

    }

    glFragColor = vec4( tot/float(AA*AA), 1.0 );
}
