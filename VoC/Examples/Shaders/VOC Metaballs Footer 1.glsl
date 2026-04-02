        len += fs / (fv[i] * fv[i]);
    }
    //len = min(16.0, len);
    len = 1.0 - len;
    return len;
}

mat4 getrotz(float angle) {
    return mat4(cos(angle), -sin(angle), 0.0, 0.0,
                sin(angle),  cos(angle), 0.0, 0.0,
                0.0,         0.0, 1.0, 0.0,
                0.0,         0.0, 0.0, 1.0);
}
mat4 getrotx(float angle) {
    return mat4(       1.0,         0.0, 0.0, 0.0,
                0.0, cos(angle), -sin(angle), 0.0,
                0.0, sin(angle), cos(angle), 0.0,
                0.0, 0.0, 0.0, 1.0);
}

float scene(vec3 p) {
    float angle = time;
    mat4 rotmat = getrotz(angle) * getrotx(angle * 0.5);
    vec4 q = rotmat * vec4(p, 0.0);
    float d = metaball(q.xyz,vec4(0.0, 0.0, 2.0 , 6.0));
    return d;
}

vec3 getN(vec3 p){
    float eps=0.001;
    return normalize(vec3(
        scene(p+vec3(eps,0,0))-scene(p-vec3(eps,0,0)),
        scene(p+vec3(0,eps,0))-scene(p-vec3(0,eps,0)),
        scene(p+vec3(0,0,eps))-scene(p-vec3(0,0,eps))
    ));
}
float AO(vec3 p,vec3 n){
    float dlt=0.5;
    float oc=0.0,d=1.0;
    for(float i=0.0;i<6.;i++){
        oc+=(i*dlt-scene(p+n*i*dlt))/d;
        d*=2.0;
    }
    
    float tmp = 1.0-oc;
    return tmp;
}

void main(void) {
    float aspect = resolution.y / resolution.x;
