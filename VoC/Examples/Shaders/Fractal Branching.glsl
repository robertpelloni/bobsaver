#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float shape(vec3 pos, float size) {
    pos = abs(pos);
    vec3 pos2 = pos-size*.8;
    return max(dot(pos,vec3(1./sqrt(3.)))-size*.8, size-length(pos2));
}

float dist(vec3 pos) {
    float scale = 1.;
    float scalef = 0.4;
    float size = 1./(scalef*(1.+scalef));
    // size*(1 + scalef) = 1/scalef
    float t = time*.3;
    mat2 m = mat2(cos(t),-sin(t),sin(t),cos(t));
    pos.xz *= m;
    pos.xy *= m;

    float result = shape(pos,scale*size);
    
    for (int i = 0; i < 4; i++) {
        //pos.yz *= m;
        pos = abs(pos);
        float a = max(max(pos.x,pos.y),pos.z);
        float b = min(min(pos.x,pos.y),pos.z);
        pos = vec3(a,pos.x+pos.y+pos.z-a-b,b);
        pos.x -= scale/scalef;
        
        scale *= scalef;
        result = min(result, shape(pos, scale*size));
    }
    
    return result;
}

void main( void ) {

    vec2 uv = ( gl_FragCoord.xy - resolution.xy*.5 )/resolution.y;
    
    vec3 pos = vec3(0,0,-9);
    vec3 dir = normalize(vec3(uv, 1.));
    
    float total = 0.;
    float gi = 0.;
    vec2 e = vec2(1e-3,0);
    vec3 color = vec3(0);
    vec3 pos0;
    float luma = 1.;
    for (int i = 0; i < 56; i++) {
        float d = dist(pos);
        if (d > 1e3) break;
        if (d < 1e-3) {
            vec3 n = normalize(vec3(dist(pos+e.xyy),dist(pos+e.yxy),dist(pos+e.yyx))-d);
            if (dot(n,dir) < 0.) {
                dir = reflect(dir,n);
                //color += (n.zxy*.25+.5+dot(n,vec3(.1)))*luma;
                luma *= .55;
            }
        }
        total += d;
        gi += 1./(max(d,0.)+.03);
        pos += dir*d;
    }

    float d = dist(pos);
    vec3 n = normalize(vec3(dist(pos+e.xyy),dist(pos+e.yxy),dist(pos+e.yyx))-d);
    n.yz *= mat2(.8,.6,-.3,.8);

    color += (-dir.xyz*.25+.5+dot(dir,vec3(.1)))*luma;
    
    glFragColor = vec4( sqrt(color),1);

}
