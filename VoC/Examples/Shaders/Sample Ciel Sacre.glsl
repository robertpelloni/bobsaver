#version 420

// original https://www.shadertoy.com/view/tlSXzD

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159
#define SOFT 0.0035

vec2 hash( vec2 p ) 
{
    p = vec2( dot(p,vec2(127.1,311.7)), dot(p,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

vec3 hash( vec3 p )
{
    p = vec3( dot(p,vec3(127.1,311.7, 74.7)),
              dot(p,vec3(269.5,183.3,246.1)),
              dot(p,vec3(113.5,271.9,124.6)));

    return -1.0 + 2.0*fract(sin(p)*43758.5453123);
}

float noise( vec3 p )
{
    vec3 i = floor( p );
    vec3 f = fract( p );
    
    vec3 u = f*f*(3.0-2.0*f);

    float v = mix( mix( mix( dot( hash( i + vec3(0.0,0.0,0.0) ), f - vec3(0.0,0.0,0.0) ), 
                               dot( hash( i + vec3(1.0,0.0,0.0) ), f - vec3(1.0,0.0,0.0) ), u.x),
                          mix( dot( hash( i + vec3(0.0,1.0,0.0) ), f - vec3(0.0,1.0,0.0) ), 
                               dot( hash( i + vec3(1.0,1.0,0.0) ), f - vec3(1.0,1.0,0.0) ), u.x), u.y),
                     mix( mix( dot( hash( i + vec3(0.0,0.0,1.0) ), f - vec3(0.0,0.0,1.0) ), 
                               dot( hash( i + vec3(1.0,0.0,1.0) ), f - vec3(1.0,0.0,1.0) ), u.x),
                          mix( dot( hash( i + vec3(0.0,1.0,1.0) ), f - vec3(0.0,1.0,1.0) ), 
                               dot( hash( i + vec3(1.0,1.0,1.0) ), f - vec3(1.0,1.0,1.0) ), u.x), u.y), u.z );
    return v;
}

float noise( vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    float v = mix( mix( dot( hash( i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ), 
                        dot( hash( i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                   mix( dot( hash( i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ), 
                        dot( hash( i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
    return v;
}

float fbm (vec2 p)
{
    return noise(p)+0.5*noise(p*2.);
}

float fbm (vec3 p)
{
    float n =0.;
    float s = 1.;
    for (int i = 0; i<6; i++)
    {
         n+= noise (p*s)/s;
        s*=2.;
    }
    return n;
}
float band(float x,float mid, float thickness)
{
    return smoothstep (mid-thickness,mid,x)-smoothstep(mid, mid+thickness,x);
}

float ring(float rMin, float rMax, float l, float soft)
{
    return  smoothstep (rMin-soft,rMin,l)-smoothstep(rMax, rMax+soft,l);    
}

float sat(float x){return clamp(x,0.,1.); }

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv-=0.5;
    vec2 uvNorm = uv*2.;

    uv *= 0.0035;
    uv *= resolution.xy;
    vec2 oldUv = uv;
    
    uv += vec2(cos(0.5*time),sin(0.33*time))*0.025;

    float pol = atan(uv.y,uv.x)+PI;
    float rad = length(uv); 
    
    float deform = 0.02 * noise(vec3(7.*oldUv, time));
    
    float rMin = 0.06 + deform +sin(time*0.5)*0.015;;
    float rMax = 0.35 + deform;
    float limit = 0.18 + deform ;
    float bands = step(limit,rad);
    float thickness = 0.0018*3.;   
    float sp = 0.25;
    float nSlice = mix(7.,9.,bands);
       float slice = 2.*PI / nSlice;
    
    pol+=time*mix(0.05,-0.05,bands);
    
    uv.x = cos(pol)*rad;
    uv.y = sin(pol)*rad;
    
    // Main shape   
    float t1 =  1.-(smoothstep(rMin, rMin +0.5*(limit-rMin),rad)-smoothstep(rMin +0.5*(limit-rMin),limit,rad));
    float t2 =  1.-(smoothstep(limit, limit +0.5*(rMax-limit),rad)-smoothstep(limit +0.5*(rMax-limit),rMax,rad));
    float nMap = mix(t1,t2,step(limit,rad));
    float reshape = 1.0;
    float nStr = 0.03 / pow(rad,0.85);  
    float nFq = 7.;
    float offsetStr = 0.2;
    
    //(pass1)
    float pol1 = pol;       
    float rot = slice*3.5*bands;
    float s = step(rad,limit);
    pol1 += rot;    
    float cellPol =-rot+(floor((pol+rot+0.5*slice)/(slice))+0.5)*(slice);
    float cellId = floor((mod(pol1+0.5*slice,2.*PI)/slice));
    float offset = hash(vec2(cellId,0.)).x*rad;
    vec2 cp = normalize(vec2(cos(cellPol),sin(cellPol)));
    pol1 = mod(pol1+0.5*slice,slice)-0.5*slice;   
    float n = nStr*4.*(fbm(uv*nFq-cp*time*sp+rad*2.));
    float li1 = band(pol1+n+offsetStr*offset,0.,thickness/(rad));
    n = mix(n, nStr*4.*(fbm(uv*nFq-cp*time*sp+rad*2.+5000.)),nMap);
    li1 = max(li1,band(pol1+n+offsetStr*offset,0.,thickness/(rad)));   
    
    //(pass2)
    pol1 = pol;       
    rot = slice*0.5+slice*3.5*bands;
    s = step(rad,limit);
    pol1 += rot;    
    cellPol =-rot+(floor((pol+rot+0.5*slice)/(slice))+0.5)*(slice);
    cellId = floor((mod(pol1+0.5*slice,2.*PI)/slice));
    offset = hash(vec2(cellId,1.)).x*rad;
    cp = normalize(vec2(cos(cellPol),sin(cellPol)));
    pol1 = mod(pol1+0.5*slice,slice)-0.5*slice;   
    n = nStr*4.*(fbm(uv*nFq-cp*time*sp+rad*2.+2000.));
    float li2 = band(pol1+n+offsetStr*offset,0.,thickness/(rad));
    n = mix(n,nStr*4.*(fbm(uv*nFq-cp*time*sp+rad*2.+5000.)),nMap);
    li2 = max(li2,band(pol1+n+offsetStr*offset,0.,thickness/(rad)));
   
    float li = max (li1,li2);
    
    float zoneMid = ring(0.,rMin,rad,SOFT);
    float mid =  (fbm(vec3(oldUv*150.,time*0.5)))-0.2;
    float ring0 = ring(rMin,rMin+0.002,rad,SOFT);
    float ringlim = ring(limit,limit+0.002,rad,SOFT);
    float zone = ring(rMin,rMax,rad,SOFT);
    
    li = max(max(li,ring0),ringlim);
    li = min (li,zone);
    li = max(li,mid*zoneMid);
    
    zone = ring(0.,rMax,rad,SOFT+0.01);
            
    vec3 liCol = mix(vec3(0.4), 1.5*vec3(0.16,0.14,0.025) , ring(0.,limit-SOFT,rad,SOFT));
    vec3 bgCol = mix(vec3(0.001,0.0045,0.1429),vec3(0.0087),zoneMid);
    vec3 mainShape = mix(bgCol*zone,liCol,li);
    
    //Stars
    pol = atan(oldUv.y,oldUv.x)+PI;
    rad = length(oldUv);    
    slice = 2.*PI/50.;
    float radSlice = 40.*pow(rad,0.24);
     
    //(pass1)
    cellPol = floor(pol/slice);
    float cellRad = floor(-0.25*time+radSlice);
    vec2 cellSpace = vec2(fract(pol/slice), fract(-0.25*time+radSlice));
    vec3 cellH = hash(vec3(cellRad,cellPol,50.))*0.5+0.5;
       
    float starRad = (cellH.y*0.032+0.02)/rad;
    float starProb = cellH.x;
    float starOs = cellH.z-0.5;
    float starLum = cellH.z;
    float stars = starProb>0.4 ? 0. : starLum*smoothstep(starRad+0.01,0.01,length(-starOs+cellSpace-0.5));
    
    //(pass2)
    pol +=0.5*slice;
    cellPol = floor(pol/slice);
    cellRad = floor(-0.5*time+150.+radSlice);
    cellSpace = vec2(fract(pol/slice), fract(-0.5*time+radSlice));
    cellH = hash(vec3(cellRad,cellPol,50.))*0.5+0.5;
       
    starRad = (cellH.y*0.032+0.02)/rad;
    starProb = cellH.x;
    starOs = cellH.z-0.5;
    starLum = cellH.z;
    stars = max(stars, starProb>0.4 ? 0. : starLum*smoothstep(starRad+0.01,0.01,length(-starOs+cellSpace-0.5)));
    stars = sat(stars);
    
    //Background
    float bgNoise = fbm(vec3(2.*oldUv/pow(rad,0.35),time*0.175))*0.5+0.5;
    bgNoise = sat (bgNoise);
    vec3 col = vec3(0);// 
    vec3 cbg1 = 0.25*vec3(0.00450,.0049,0.0138); vec3 cbg2 = vec3(0.0052,0.0055,0.03);
    col = mix(cbg1,cbg2,bgNoise);
    col = mix(col, 1.*vec3(0.003,0.003,0.035), smoothstep(0.5,0.71,bgNoise));
    col = mix(col*0.75,col,  smoothstep(0.3,0.35,bgNoise));
    col *=0.75;
    stars += (0.2*sat(mid) *(smoothstep(0.5,0.7,bgNoise)-smoothstep(0.9,1.,bgNoise)));
    col += mix (col, vec3(0.3),stars);
    
    col = mix (col, mainShape, zone);
    
    //shadow
    pol = atan(uv.y,uv.x)+PI;
    rad = length(uv); 
    
    pol += noise(vec2(rad*50.,0.5*time));
    pol = mod(pol, 2.*PI);   
    float v = sat((1.-zone)*(1.-(rad-rMax )/ (0.05+sin(pol*2.)*0.025)));
    col = mix(col, col*0.2, v);
    
    //vignette and noise
    col = mix(col,col*0.5,hash(oldUv).x);
    col *= 0.3+(1.-length(uvNorm));
    
    //texture
    float pap = 1.-length((fract(oldUv*70.+vec2(0.,noise(0.5*oldUv*100.+5000.)))-0.5)/0.7);
    pap = sat(pap+0.5);
    col *= pap;
    
    //the end
    col = pow(col,vec3(0.45));
    glFragColor = vec4(col,1.0);
}
