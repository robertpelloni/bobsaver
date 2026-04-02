#version 420

// original https://www.shadertoy.com/view/tsfyz4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float PI = 3.1415;
float PHI = 1.61803398874989;
const int steps = 16;

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
// this function from https://www.shadertoy.com/view/wtSSWh
float n(vec2 u){
    vec4 d=vec4(.106,5.574,7.728,3.994),q=u.xyxy,p=floor(q);
    ++p.zw;
    q-=p;
    p=fract(p*d.xyxy);
    d=p+d.wzwz;
    d=p.xxzz*d.ywyw+p.ywyw*d.xxzz;
    p=fract((p.xxzz+d)*(p.ywyw+d));
    p=cos(p*=time+d)*q.xxzz+sin(p)*q.ywyw;
    q*=q*(3.-2.*q);
    p=mix(p,p.zwzw,q.x);
    return mix(p.x,p.y,q.y);
}

// these three functions are from http://mercury.sexy/

// The "Round" variant uses a quarter-circle to join the two objects smoothly:
float fOpUnionRound(float a, float b, float r) {
    vec2 u = max(vec2(r - a,r - b), vec2(0));
    return max(r, min (a, b)) - length(u);
}

float fOpIntersectionRound(float a, float b, float r) {
    vec2 u = max(vec2(r + a,r + b), vec2(0));
    return min(-r, max (a, b)) + length(u);
}

float fOpDifferenceRound (float a, float b, float r) {
    return fOpIntersectionRound(a, -b, r);
}

float virusHead (float p){
    
    return cos(p);//+ noise(abs(p));
}

float modBlob(inout vec3  p){
        float sz = 0.;
    if (p.x < max(p.y, p.z)){ 
        p = p.yzx;
        //sz+=.007;
    }
    if (p.x < max(p.y, p.z)){ 
       // sz-=0.05;
        p = p.yzx;}

    return sz;
    
}

float bFunct(vec3 p, vec3 savedP){ // this function places nubs around sphere
   return  max(max(max(
        dot(p, normalize(vec3(1., 1, 1))),
        dot(p.xz, normalize(vec2(PHI+1., 1.)))),
        dot(p.yx, normalize(vec2(1., PHI )))),
        dot(p.xz, normalize(vec2(1., PHI ))));
    
}

float bloby(vec3 p) {
    p = abs(p);
    vec3 savedP = p;
    float sz = 1.3;
    sz += modBlob(p);
    float b = bFunct(p,savedP);
    float l = length(p);
    
    float nub =(1.01 - b / l)*(PI / .04) - n(savedP.xy*20.);
        
    float sploops = l - sz - 0.09 * cos(min(nub, (PI)));
    
    return fOpDifferenceRound (sploops,l-1.38, 0.15); // just ge tthe nubs
}

float virus(vec3 p) {
    vec3 savedP = p;
    p = abs(p);
float sz = 1.2;
 sz += modBlob(p);
    float b = bFunct(p,savedP);
        
    float l = length(p);
    return l - sz - 0.3 * (3. / 2.)* cos(min(sqrt(1.01 - b / l)*(PI / 0.15), PI )) +( n(savedP.xy*20.) *0.01)+  n(savedP.zy*17.) *0.03;
}
//from http://mercury.sexy/
void pR(inout vec2 p, float a) {
    p = cos(a)*p + sin(a)*vec2(p.y, -p.x);
}
float scene(vec3 ray){
    float time = time;
    float floor = (ray.y + 1.2) - 
        cos(ray.x * 10.)* 0.2 - sin(ray.y* 10.);
    float radius = 0.5;
    
    
   // ray = mod(ray, modSpace) - 0.5*modSpace;
    
    ray = ray - vec3(0.,0.,2.0);
    vec3 ray2 = ray;
    vec3 ray3 = ray;
        
    pR(ray2.yz,time/3. + n((vec2(time/3. ) / 2.)) * 0.2);
    pR(ray3.yz,time/3.);
    
    vec3 ray4 = mix(ray2,ray3,(sin(time)/5.) + 1.);
    
    pR(ray4.xz, n(vec2(time/4.) ) );
    
    pR(ray4.xy, 0.2*n(vec2(time) ) ); 
    float blob = bloby(ray4);
    float virus = virus(ray4);

    return smin(blob,virus,.8  + (0.08* sin(time)));//smin(smin(blob, sphere,0.6), sphere2,0.6) ;
}

vec3 estimateNormal(vec3 p) {
    float smallNumber = 0.002;
    vec3 n = vec3(
    scene(vec3(p.x + smallNumber, p.yz)) -
    scene(vec3(p.x - smallNumber, p.yz)),
    scene(vec3(p.x, p.y + smallNumber, p.z)) -
    scene(vec3(p.x, p.y - smallNumber, p.z)),
    scene(vec3(p.xy, p.z + smallNumber)) -
    scene(vec3(p.xy, p.z - smallNumber))
);

    return normalize(n);
}

float lighting(vec3 origin, vec3 dir, vec3 normal) {
    vec3 lightPos = vec3(12,12,1);//vec3(cos(time) +12., sin(time), 12.);
    vec3 light = normalize(lightPos - origin);

    float diffuse = max(0., dot(light, normal));
    vec3 reflectedRay = 2.2 * dot(light, normal) * normal - light;

    float specular = max(0., (pow(dot(reflectedRay, light),5.)));

    float ambient = 0.03;

    return ambient + diffuse + specular;

}

vec4 trace(vec3 rayOrigin, vec3 dir){
    vec3 ray = rayOrigin;
    float dist = 0.; 
    float totalDist = 0.;
    float maxDist = 3.;
    
    for (int i = 0; i < steps ; i++){
        dist = scene(ray);
        
        if(dist < 00.04){
            vec4 distCol = vec4(1. - vec4(totalDist/maxDist));
            vec4 lightingCol = vec4(lighting(rayOrigin,dir,estimateNormal(ray)));
            vec4 col = lightingCol;//mix(lightingCol , vec4(distCol),distCol.x);
           
            return col;
        } 
        totalDist += dist;
        ray += dist * dir;
        if (totalDist > maxDist){
            break;
            
        }
    } 
 

    return vec4(n(rayOrigin.xy*2.0) * (1.6-length(rayOrigin.xy)));
}
vec3 lookAt(vec2 uv, vec3 camOrigin, vec3 camTarget){
    vec3 zAxis = normalize(camTarget - camOrigin);
    vec3 up = vec3(0,1,0);
    vec3 xAxis = normalize(cross(up, zAxis));
    vec3 yAxis = normalize(cross(zAxis, xAxis));

    float fov = 2.;

    vec3 dir = (normalize(uv.x * xAxis + uv.y * yAxis + zAxis * fov));

    return dir;
}

void main(void)
{
    float time = time;
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = gl_FragCoord.xy/resolution.xy;
    uv = (uv *2.)-1.;

    uv.x *= resolution.x/resolution.y;
    vec3 rayOrigin = vec3(uv.x + n(vec2(time))*0.05,uv.y + n(vec2(time/3.))*0.03, 0.); // TODO make it so that the bg moves more than the foreground so it looks like the fbm is far away
    vec3 camOrigin = vec3(0, 0., -1.);

    vec3 camTarget = camOrigin+ vec3(sin(time/10.),cos(time/10.), 2);

    vec3 direction = lookAt(uv, camOrigin, camTarget);

    glFragColor = (trace(rayOrigin, direction));
}
