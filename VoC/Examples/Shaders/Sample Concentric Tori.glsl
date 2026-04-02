#version 420

// original https://www.shadertoy.com/view/tllGRM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359
const int MAX_MARCHING_STEPS = 164;
const float EPSILON = 0.0015;
const float NEAR_CLIP = 0.0;
const float FAR_CLIP = 80.00;

vec3 lightDirection = vec3(0.702, 0.1686, 0.6745);

// https://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opSubtraction( float d1, float d2 ) { return max(-d1,d2); }

float sdBox( vec3 p, vec3 b ){
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float onion( in float d, in float h ){
    return abs(d)-h;
}

float sdTorus( vec3 p, vec2 t ){
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float bendTorus( vec3 p, vec2 dim ){
    float wave = sin(time * 2.0) * 0.2;
    float c = cos(wave*p.x);
    float s = sin(wave*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3( p.xy*m, p.z);
    return sdTorus(q, dim);
}

float bendBox( vec3 p, vec3 dim ){
    float wave = sin(time * 2.0) * 0.2;
    float c = cos(wave*p.x);
    float s = sin(wave*p.x);
    mat2  m = mat2(c,-s,s,c);
    vec3  q = vec3( p.x, m*p.yz);
    return sdBox(q, dim);
}

float map(vec3 pos){
    float thick = 0.08;
    float d = onion(bendTorus( pos.xzy, vec2(1.0,0.2) ), thick);
    
    d = max( d, pos.y+cos(time+1.2));
    float d1 = onion(bendTorus( pos.xzy, vec2(1.1,0.5) ), thick-0.01);
    d1 = max( d1, pos.x+sin(time-0.3));

    float d2 = onion(bendTorus( pos.xzy, vec2(1.2,0.8) ), thick-0.02);
    d2 = max( d2, pos.y+cos(time-0.9));
    
    float d3 = onion(bendTorus( pos.xzy, vec2(1.3,1.1) ), thick-0.03);
    d3 = max( d3, pos.x+sin(time+0.5));

    vec3 posBox = pos;
    float boxZ = 0.1;
    float box = bendBox(posBox, vec3(12.5, 3.1, boxZ));
    
    // cut it all in half so that the interior parts are visible
    float tori = min(d3,min(d2,min(d1, d)));
    return opSubtraction(box,tori);
}    

vec2 squareFrame(vec2 res, vec2 coord){
    vec2 uv = 2.0 * coord.xy / res.xy - 1.0;
    uv.x *= res.x / res.y;
    return uv;
}

float raymarching(vec3 eye, vec3 marchingDirection){
    float depth = NEAR_CLIP;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = map(eye + depth * marchingDirection);
        if (dist < EPSILON){
            return depth;
        }

        depth += dist;

        if (depth >= FAR_CLIP) {
            return FAR_CLIP;
        }
    }
    return FAR_CLIP;
}

float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax ) {
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ ) {
        float h = map( ro + rd*t );
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}

float ao( in vec3 pos, in vec3 nor ){
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.06*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos );
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

vec3 computeNormal(vec3 pos){
    vec2 eps = vec2(0.01, 0.);
    return normalize(vec3(
        map(pos + eps.xyy) - map(pos - eps.xyy),
        map(pos + eps.yxy) - map(pos - eps.yxy),
        map(pos + eps.yyx) - map(pos - eps.yyx)
    ));
}

float diffuse(vec3 normal){
    float ambient = 0.3;
    return clamp( dot(normal, lightDirection) * ambient + ambient, 0.0, 1.0 );
}

float specular(vec3 normal, vec3 dir){
    vec3 h = normalize(normal - dir);
    float specularityCoef = 40.;
    return clamp( pow(max(dot(h, normal), 0.), specularityCoef), 0.0, 1.0);
}

float fresnel(vec3 normal, vec3 dir){
    return pow( clamp(1.0+dot(normal,dir),0.0,1.0), 2.0 );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr ){
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void main(void)
{
    vec2 uv = squareFrame(resolution.xy,gl_FragCoord.xy);

    float camSpeed = 1.0;
    vec3 eye = vec3( 
               0.5+2.5*sin(camSpeed*time),
                2.5,
                2.3 - 3.0*cos(camSpeed*time)
    );

    vec3 ta = vec3(0.0, 0.0, 0.0);
    mat3 camera = setCamera( eye, ta, 0.0 );
    float fov = 1.5;
    vec3 dir = camera * normalize(vec3(uv, fov));
    
    float shortestDistanceToScene = raymarching(eye, dir);

    vec3 color;
    vec3 bgColor = vec3(0.086, 0.290, 0.800);

    if (shortestDistanceToScene < FAR_CLIP - EPSILON) {
        vec3 collision = (eye += (shortestDistanceToScene*0.995) * dir );
        float shadow  = softshadow(collision, lightDirection, 0.02, 2.5 );
        vec3 normal = computeNormal(collision);
        float diffLight = diffuse(normal);
        float specLight = specular(normal, dir);
        float fresnelLight = fresnel(normal, dir);
        float ambientOcc = ao(collision, normal);
        vec3 texCol = vec3(1.00, 0.352, 0.207);
        color = (diffLight + specLight + fresnelLight) * texCol;
        
        shadow = mix(shadow, 1.0, 0.7);
        color = color * ambientOcc * shadow;

    } else {
        color = bgColor;
    }
    

    glFragColor = vec4(clamp(color,0.0,1.0) , 1.0);
}
