#version 420

// original https://www.shadertoy.com/view/Ml23RG

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// 2015-04-26 jnorberg
// I wanted to test out panoramic projection

// menger sponge "inspired" by FMS_Cat 20141207 Menger Sponge
// AO from iq's Raymarching - Primitives

float box(vec3 p,vec3 b)
{
    vec3 d=abs(p)-b;
    return min(max(d.x,max(d.y,d.z)),0.)+length(max(d,0.));
}

float bar(vec2 p,vec2 b)
{
    vec2 d=abs(p)-b;
    return min(max(d.x,d.y),0.)+length(max(d,0.));
}

float crossBar(vec3 p,float b)
{
    float
        da=bar(p.xy,vec2(b)),
        db=bar(p.yz,vec2(b)),
        dc=bar(p.zx,vec2(b));
    
    return min(da,min(db,dc));
}

float distFunc(vec3 p)
{
    // repeating space
    p.x = mod( p.x+0.4, 0.8 ) - 0.4; 
    p.y = mod( p.y+0.4, 0.8 ) - 0.4; 
    p.z = mod( p.z+0.4, 0.8 ) - 0.4; 

    float ret=box(p,vec3(0.3));

    for( float c = 0.0 ; c < 4.0 ; c += 1.0)
    {
        float pw=pow(3.0,c);
        ret=max(ret,-crossBar(mod(p+.15/pw,.6/pw)-.15/pw,.1/pw));
    }
    return ret;
}

vec3 getNormal(vec3 p)
{
    float d=1E-3;
    return normalize(vec3(
        distFunc(p+vec3(d,0.,0.))-distFunc(p+vec3(-d,0.,0.)),
        distFunc(p+vec3(0.,d,0.))-distFunc(p+vec3(0.,-d,0.)),
        distFunc(p+vec3(0.,0.,d))-distFunc(p+vec3(0.,0.,-d))
    ));
}

float getAO( vec3 pos, vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<3; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = distFunc( aopos );
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

void main(void)
{
    //return;
    
    vec2 pix=( gl_FragCoord.xy*2.0 - resolution.xy) / resolution.x;
    
    vec3 camP=vec3(
        0.05 * sin(time*0.2 ),
        0.05 * sin(time*0.15 ),
        0.1*time
    );

    vec3 camC= camP + vec3(
        0.3 * sin(time*0.05),
        0.3 * sin(time*0.06),
        1.);

    vec3 camA=vec3(0.3*sin(time*0.03),0.8,0.);
    vec3 camS=cross(normalize(camC-camP),camA);
    vec3 camU=cross(camS,normalize(camC-camP));
    
    vec3 camF = normalize(camC-camP );

    // panoramic projection by aiming rays using angles
    vec3 ray=normalize(
        camS*sin(pix.x*3.5) + camF*cos(pix.x*3.5) +
        camU*pix.y*3.14
    );
    
    float dist=0.;
    float rayL=0.;
    vec3 rayP=camP;
    
    for(int i=0;i<32;i++){
        dist=distFunc(rayP);
        rayL+=dist;
        rayP=camP+ray*rayL;
    }
    
    vec3 nor=getNormal(rayP);

    // lame point light at camera
    float lum=0.5-dot(ray,nor);
    lum *= 1.0/(rayL*4.0 + 1.0);
    lum *= getAO( rayP, nor );
        
    // phase
    float p = 3.0*rayP.x + 3.0*rayP.y + 3.0*rayP.z;
        
    // rainbow
    float r = 0.6 + 0.4 * sin( p );
    float g = 0.6 + 0.4 * sin( p + 1.03);
    float b = 0.6 + 0.4 * sin( p + 2.07 );
        
    // brighten color
    float m = max(r, max(g,b));
    vec3 colHi = vec3(r,g,b) / m;
        
    // darken (but saturated) color
    float lo = min(colHi.r, max(colHi.g,colHi.b));
    vec3 colLo = colHi - vec3(lo);
    
    // final color
    glFragColor=vec4(mix(colLo,colHi,lum),1.0);
}
