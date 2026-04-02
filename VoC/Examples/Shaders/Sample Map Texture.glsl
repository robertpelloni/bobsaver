#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec2 xyzToPolar(vec3 xyz){
    float theta = atan(xyz.y, xyz.x);
    float phi = acos(xyz.z);
    return vec2(theta, phi) / vec2(2.0 *3.1415,  3.1415);
}

vec3 polarToXyz(vec2 xy){
    xy *= vec2(2.0 *3.1415,  3.1415);
    float z = cos(xy.y); 
    float x = cos(xy.x)*sin(xy.y); 
    float y= sin(xy.x)*sin(xy.y);
        return normalize(vec3(x,y,z));
}

float hash( float n ){
    return fract(sin(n)*758.5453);
}
float noise4d(vec4 x){
    vec4 p=floor(x);
    vec4 f=smoothstep(0.,1.,fract(x));
    float n=p.x+p.y*157.+p.z*113.+p.w*971.;
    return mix(mix(mix(mix(hash(n),hash(n+1.),f.x),mix(hash(n+157.),hash(n+158.),f.x),f.y),
    mix(mix(hash(n+113.),hash(n+114.),f.x),mix(hash(n+270.),hash(n+271.),f.x),f.y),f.z),
    mix(mix(mix(hash(n+971.),hash(n+972.),f.x),mix(hash(n+1128.),hash(n+1129.),f.x),f.y),
    mix(mix(hash(n+1084.),hash(n+1085.),f.x),mix(hash(n+1241.),hash(n+1242.),f.x),f.y),f.z),f.w);
} 
float noise4d2(vec4 a) {
    return (noise4d(a) + noise4d((a) + 100.5)) * 0.5;
}
float fbm(vec4 a){
    return noise4d2(a) * 0.5 
        +noise4d2(a*2.0) * 0.25 
        +noise4d2(a*4.0) * 0.125 
        +noise4d2(a*8.0) * 0.065 
        +noise4d2(a*16.0) * 0.032;
}
float fbm2(vec4 a){
    return fbm(a + (vec4(fbm(a + 100.0), fbm(a + 300.0), fbm(a + 600.0), 0.0) * 2.0 - 1.0));
}
mat3 rotationMatrix(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat3(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s,
        oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s,
        oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c);
}
void main( void ) {

    vec2 position = ( gl_FragCoord.xy / resolution.xy ); 
    vec3 dir = rotationMatrix(vec3(0.0, 0.0, 1.0), time * 0.1) * polarToXyz(position);
    float clouds = smoothstep(0.45, 0.6, fbm2(vec4(dir * 5.0, 0.04 * time)));
    float wetdry = smoothstep(0.44, 0.44, fbm2(vec4(dir * 2.0, 0.0)));
    glFragColor = vec4(mix(mix(vec3(0.7, 0.8, 0.2), vec3(0.1, 0.3, 0.6), wetdry), vec3(1.0), clouds), 1.0);

}
