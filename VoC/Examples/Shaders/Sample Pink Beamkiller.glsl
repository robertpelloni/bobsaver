#version 420

// original https://www.shadertoy.com/view/tdsfD8

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

//
// friol 2o2o
// sdf functions by iq
// music by Twisterium
// 02.05.2020: slightly enlarged beamrays
//

const int iterationAmount=512;

float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

vec3 rotx(in vec3 p, float a) 
{
    return vec3(p.x,
                cos(a) * p.y + sin(a) * p.z,
                cos(a) * p.z - sin(a) * p.y);
}

vec3 roty(in vec3 p, float a) {
    return vec3(cos(a) * p.x + sin(a) * p.z,
                p.y,
                cos(a) * p.z - sin(a) * p.x);
}

vec3 rotz(in vec3 p, float a) {
    return vec3(cos(a) * p.x + sin(a) * p.y,
                cos(a) * p.y - sin(a) * p.x,
                p.z);
}

float opSmoothUnion( float d1, float d2, float k ) {
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h); }

float sdSphere(vec3 p, float r)
{
    return length(p) - r;
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

float sdPlane( vec3 p, vec4 n )
{
  return dot(p,n.xyz) + n.w;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
  vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
  return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

float sdCappedCylinder( vec3 p, float h, float r )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - vec2(h,r);
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}

float sdInvertedBox( vec3 p, vec3 b )
{
  vec3 q = abs(p) - b;
  return -length(max(q,0.0)) - min(max(q.x,max(q.y,q.z)),0.0);
}

// 3D hash function
float hash(vec3 p)
{
    p  = fract( p*0.3183099+.1 );
    p *= 17.0;
    return fract( p.x*p.y*p.z*(p.x+p.y+p.z) );
}

// 3D precedural noise
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    return mix(mix(mix( hash(p+vec3(0,0,0)), 
                        hash(p+vec3(1,0,0)),f.x),
                   mix( hash(p+vec3(0,1,0)), 
                        hash(p+vec3(1,1,0)),f.x),f.y),
               mix(mix( hash(p+vec3(0,0,1)), 
                        hash(p+vec3(1,0,1)),f.x),
                   mix( hash(p+vec3(0,1,1)), 
                        hash(p+vec3(1,1,1)),f.x),f.y),f.z);
}

//
//
//

vec2 SDF(vec3 r)
{
    float mat=0.0;
    vec3 origR=r;
    float rotTime=time/1.0;
    float fft = 0.0;//texture( iChannel0, vec2(0.0,0.0) ).x;
    float cylRad=0.15+0.1*fft;
    
    r=rotz(r,rotTime);
    r=roty(r,-rotTime);
    float t = sdCylinder(r,vec3(0.0,0.0,cylRad));
    r=rotx(r,3.141592/2.0);
    float t2 = sdCylinder(r,vec3(0.0,0.0,cylRad));
    r=rotz(r,3.141592/2.0);
    float t3 = sdCylinder(r,vec3(0.0,0.0,cylRad));
    
    t=min(min(t,t2),t3);
    
    return vec2(t,1.0);
}

vec2 SDFsolid(vec3 r)
{
    vec3 origR=r;
    float t=1000.0;
    float rotTime=time/1.0;

    r=rotz(r,rotTime);
    r=roty(r,-rotTime);

    float fft = 0.0;//texture( iChannel0, vec2(0.0,0.0) ).x;
    //float rbox = sdRoundBox(r,vec3(.5,.5,.5),.1);
    float rbox = sdSphere(r,.69+fft*0.33);
    float amt=10.0;
    //rbox+=0.2*(0.5+abs(sin(time)))*cos(r.x*amt)*sin(r.y*amt)*cos(r.z*amt);
    rbox+=(.10+0.05*fft)*cos(r.x*amt)*(sin(r.y*amt))*cos(r.z*amt);
    t=rbox;
    
    float cyllen=.55;
    float cylrad=.19;
    float tcyl0=sdCappedCylinder(r,cylrad,cyllen);
    t=min(t,tcyl0);
    r=rotx(r,3.141592/2.0);
    float tcyl1=sdCappedCylinder(r,cylrad,cyllen);
    t=min(t,tcyl1);
    r=rotz(r,3.141592/2.0);
    float tcyl2=sdCappedCylinder(r,cylrad,cyllen);
    t=min(t,tcyl2);
    
    /*
    origR+=vec3(0.0,0.0,time);
    int numq=5;
    for (int i=0;i<numq;i++)
    {
        float c=.9;
        vec3 q = vec3(origR.x,origR.y,mod(origR.z+0.5*c,c)-0.5*c);
        vec3 rotatedr=rotz(q,(float(i)*3.141592*2.0)/float(numq));
        //float abox=sdRoundBox(rotatedr-vec3(0.0,-2.3,4.0),vec3(1.82,.01,3.5),.1);
        float box=sdSphere(rotatedr-vec3(0.0,-1.0,0.0),.2);
        //float box=sdPlane(rotatedr-vec3(0.0,-1.0,0.0),vec4(0.0,1.0,0.0,1.0));
        t=min(t,box);
    }
    */
    
    float ibox=sdInvertedBox(origR,vec3(5.5));
    t=min(t,ibox);

    if ((t==tcyl0)||(t==tcyl1)||(t==tcyl2)) return vec2(t,3.0);
    if (t==rbox) return vec2(t,2.0);
    return vec2(t,4.0);
}

vec3 calcNormal(vec3 pos)
{
    vec3 n = vec3(0.0);
    for( int i=0; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3(( mod(float((i+3)/2),2.0) ),(mod(float(i/2),2.0)),(mod(float(i),2.0)))-1.0);
        n += e*SDFsolid(pos+0.0005*e)[0];
    }
    return normalize(n);
}

vec4 castRay(vec3 rayOrigin, vec3 rayDir)
{
    float mintlc=100000.0;
    float lightAccum=0.0;
    float fogAccum=0.0;
    
    float fft = 0.0;//texture( iChannel0, vec2(0.0,0.0) ).x;
    
    // light cone
    float tlc = 0.0;
    for (int i = 0; i < iterationAmount; i++)
    {
        vec2 res = SDF(rayOrigin + rayDir * tlc);
        if (res[0]<0.0)
        {
            float fact=distance(vec3(0.),rayOrigin + rayDir * tlc);
            float k=(abs(noise((rayOrigin+rayDir*tlc))));
            //k*=0.02;
            k*=0.08*fft;
            //float cnst=0.08;
            lightAccum+=mix(k,0.08,0.4)/fact;
            //lightAccum+=k/fact;
            if (tlc<mintlc) mintlc=tlc;
        }
        tlc += 0.0155;
    }
    
    //lightAccum/=2.0;
    //lightAccum=clamp(lightAccum,0.0,1.0);
    
    // solid shapes
    float t=0.0;
    for (int i = 0; i < iterationAmount; i++)
    {
        vec2 res = SDFsolid(rayOrigin + rayDir * t);
        if (res[0] < (0.0001*t))
        {
            if (lightAccum>0.0)
            {
                vec3 vecLight=rayOrigin+rayDir*mintlc;
                vec3 vecSolid=rayOrigin+rayDir*t;
                
                if (distance(rayOrigin,vecSolid)<=distance(rayOrigin,vecLight))
                {
                    return vec4(t,res[1],0.0,fogAccum);
                }
                else
                {
                    return vec4(t,res[1],lightAccum,fogAccum);
                }
            }
            else
            {
                return vec4(t,res[1],0.0,fogAccum);
            }
        }

        float n=abs(noise((rayOrigin+rayDir*tlc)));
        //n=cos(n)*n*sin(n);
        fogAccum+=n*0.04;
        t += res[0];
    }
    
    if (lightAccum>0.0) return vec4(0.0,1.0,clamp(0.0,1.0,lightAccum),fogAccum);
     
    return vec4(-1.0,-1.0,-1.0,-1.0);
}

vec4 render(vec3 rayOrigin, vec3 rayDir, vec2 uv)
{
    vec3 col=vec3(0.);
    vec3 L=normalize(vec3(0.0,0.0,-1.0));

    vec4 rayHit = castRay(rayOrigin, rayDir);
    float mat=rayHit[1];
    vec3 pHit=rayOrigin+rayDir*rayHit[0];
    float fft = 0.0; //texture( iChannel0, vec2(0.0,0.0) ).x;

    if (mat==1.0)
    {
        col=vec3(1.0,1.0,1.0)*rayHit[2];
    }
    else if (((mat==2.0)||(mat==3.0))||(mat==4.0))
    {
        vec3 N=calcNormal(rayOrigin + rayDir * rayHit[0]);
        if (mat==2.0) 
        {
            float rotTime=time/4.0;
            vec3 N2=N;
            N2=rotz(N2,rotTime);
            N2=roty(N2,-rotTime);
            vec2 matuv = vec2( atan(N2.x,N2.z), acos(N2.y ) );
            float intensity=max((dot(N2,L)),0.0);
            intensity+= pow(intensity, 2.0);            
            //col=texture(iChannel0,matuv).rrr;
            //col=mix(col,vec3(intensity),0.9);
            //col=vec3(intensity*0.817,intensity*0.32,intensity*0.5);
            vec3 colstart=vec3(0.03,0.045,0.18);
            vec3 colenddd=vec3(0.817,0.32,0.5);
            col=mix(colstart,colenddd,intensity/2.0);
        }
        else if (mat==3.0) 
        {
            float NoL=max(dot(N, L),0.0);
            col=vec3(1.,1.,1.)*NoL;
        }
        else if (mat==4.0) 
        {
            //vec3 ll=vec3(1.0,0.0,0.0);
            //float NoL=max(dot(N, ll),0.0);
            //float intens=0.1;
            //col=vec3(intens)*NoL;
            //col+=vec3(0.1,0.1,0.4);
            //col/=pHit.z/3.2;
            vec2 a=vec2(1.0);
            if ((N.z>0.01)||(N.z<-0.01))
            {
                a=vec2(
                    vec2(1.)*smoothstep(-0.05, 0.05, mod(pHit.x, 1.))*
                    smoothstep(-0.05, 0.05, mod(pHit.y, 1.)));
            }
            else if ((N.x>0.01)||(N.x<-0.01))
            {
                a=vec2(
                    vec2(1.)*smoothstep(-0.05, 0.05, mod(pHit.y, 1.))*
                    smoothstep(-0.05, 0.05, mod(pHit.z, 1.)));
            }
            else if ((N.y>0.01)||(N.y<-0.01))
            {
                a=vec2(
                    vec2(1.)*smoothstep(-0.05, 0.05, mod(pHit.x, 1.))*
                    smoothstep(-0.05, 0.05, mod(pHit.z, 1.)));
            }
            col = vec3(.6-a.x,.7-a.y,0.8-a.x);
            //col*=NoL;
        }
        
        // add fog
        col+=vec3(rayHit[3]);
        
        // add lightrays
        col+=vec3(rayHit[2]);
        
        // add beat
        if (time>15.0) col+=pow(fft,16.0);
    }
    else
    {
        col=vec3(0.0,0.0,0.0);
    }

    //col=fog(col,, vec3 fxcol)
    col=pow(col,vec3(0.58));
    return vec4(col,1.0);
}

vec3 getCameraRayDir(vec2 uv, vec3 camPos, vec3 camTarget)
{
    vec3 camForward = normalize(camTarget - camPos);
    vec3 upz=vec3(0.,1.,0.);
    vec3 camRight = normalize(cross(upz, camForward));
    vec3 camUp = normalize(cross(camForward, camRight));
     
    float fPersp = 2.0;
    vec3 vDir = normalize(uv.x * camRight + uv.y * camUp + camForward * fPersp);
 
    return vDir;
}

vec2 normalizeScreenCoords(vec2 screenCoord)
{
    vec2 result = 2.0 * (screenCoord/resolution.xy - 0.5);
    result.x *= resolution.x/resolution.y;
    return result;
}

float onelinerRandom(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main(void)
{
    float myTime=time;
    float rotTime=time*1.5;
    vec2 uv = normalizeScreenCoords(gl_FragCoord.xy);

    vec3 camPos,camTarget;
    
    float fft = 0.0; //texture( iChannel0, vec2(0.0,0.0) ).x;
    float radius=2.0+2.0*abs(sin(time));
    //camPos = vec3(radius*sin(myTime),0.0,-radius*cos(myTime));
    //camTarget = vec3(0.0,cos(myTime)*2.0,0.0);
    camPos=vec3(radius*sin(rotTime),2.0*sin(rotTime),-radius*cos(rotTime));
    camTarget=vec3(0.0,0.0,0.0);
    
    vec3 rayDir = getCameraRayDir(uv, camPos, camTarget);   

    vec4 finalCol = vec4(render(camPos, rayDir,uv).xyz,1.0);
    finalCol+=0.09;    
    glFragColor=vec4(finalCol.rgb, 1.0);
}
