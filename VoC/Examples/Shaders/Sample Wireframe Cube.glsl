#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec3 _scale = vec3(1.0);
vec3 _position = vec3(0.0);
vec4 _color = vec4(1.0);
float _lineWidth = 0.002;

// unormalize and shift coordinates to the center
vec4 frag;
#define coord (gl_FragCoord.xy / resolution.y - vec2((resolution.x/resolution.y)/2.0, 0.5)) * vec2(2)

mat4 mat = mat4(1, 0, 0, 0,
          0, 1, 0, 0,
          0, 0, 100.1/-99.9, -1,
          0, 0, 20./-99.9, 0);

vec3 point (vec3 p){
    vec4 pp = mat * vec4(p, 1);
    return pp.xyz / pp.w;
}

void translate (vec3 p){
    mat[3].x += mat[0].x * p.x + mat[1].x * p.y + mat[2].x * p.z;
    mat[3].y += mat[0].y * p.x + mat[1].y * p.y + mat[2].y * p.z;
    mat[3].z += mat[0].z * p.x + mat[1].z * p.y + mat[2].z * p.z;
    mat[3].w += mat[0].w * p.x + mat[1].w * p.y + mat[2].w * p.z;
}

void rotateY(float dude){
    float s = sin(dude);
    float c = cos(dude);
    
    mat *= mat4(c, 0, s, 0, 0, 1, 0, 0, -s, 0, c, 0, 0, 0, 0, 1);
}

void rotateZ(float dude){
    float s = sin(dude);
    float c = cos(dude);
    
    mat *= mat4(c, -s, 0, 0, s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
}

void scale(vec3 d){
    mat *= mat4(d.x, 0, 0, 0, 0, d.y, 0, 0, 0, 0, d.z, 0, 0, 0, 0, 1);
}

/**
* Projects a 3D point intto 2D space
* and store computed depth into z component.
* Applies current _scale and _position. 
**/
vec3 computePoint(vec3 point){
    point += _position;
    point *= _scale;
    point.z = point.z + 1.0;
    point.xy *= point.z;
    return point;
}
    
vec4 line(vec3 point0, vec3 point1){
    vec3 p0 = point(point0);
    vec3 p1 = point(point1);
    
    
    vec2 d = normalize(p1.xy - p0.xy);
    float slen = distance(p0.xy, p1.xy);
    
    float     d0 = max(abs(dot(coord - p0.xy, d.yx * vec2(-1.0, 1.0))), 0.0),
        d1 = max(abs(dot(coord - p0.xy, d) - slen * 0.5) - slen * 0.5, 0.0);
    
    float value = step(length(vec2(d0, d1)),_lineWidth);
    
    vec4 color = vec4(vec3(value), 1.0);
    
    color *= _color;
    
    return color;
}

vec4 cube(){
    vec4 color=vec4(0.,0.,0.,1.);
    color += line(vec3(-0.5,0.5,-0.5), vec3(0.5,0.5,-0.5));
    color += line(vec3(0.5,0.5,-0.5), vec3(0.5,-0.5,-0.5));
    color += line(vec3(0.5,-0.5,-0.5), vec3(-0.5,-0.5,-0.5));
    color += line(vec3(-0.5,-0.5,-0.5), vec3(-0.5,0.5,-0.5));
    
    color += line(vec3(-0.5,0.5,0.5), vec3(0.5,0.5,0.5));
    color += line(vec3(0.5,0.5,0.5), vec3(0.5,-0.5,0.5));
    color += line(vec3(0.5,-0.5,0.5), vec3(-0.5,-0.5,0.5));
    color += line(vec3(-0.5,-0.5,0.5), vec3(-0.5,0.5,0.5));
    
    color += line(vec3(-0.5,0.5,-0.5), vec3(-0.5,0.5,0.5));
    color += line(vec3(0.5,0.5,-0.5), vec3(0.5,0.5,0.5));
    color += line(vec3(0.5,-0.5,-0.5), vec3(0.5,-0.5,0.5));
    color += line(vec3(-0.5,-0.5,-0.5), vec3(-0.5,-0.5,0.5));
    
    return color;
}
void main( void ) {
    translate(vec3(0, 0, -2));
    
    rotateY(time);
    rotateZ(time);
    
    scale (vec3(sin(time)));
    
    glFragColor = cube();
}
