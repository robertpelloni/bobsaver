#version 420

// original https://www.shadertoy.com/view/7lyBRV

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int ITER = 25;
const int pnum= 3 ;

vec3 drawpoint(vec2 uv, vec2 pos, float r, vec3 col, vec3 col1) {
 vec3 rescol;

 rescol= mix( col, col1, step(distance(uv, pos), r));
 rescol=mix(rescol, vec3(1.), smoothstep(r*.7,r*.04,distance(uv,pos)));

 return rescol;
}

vec3 magnets (vec2 p, vec2 pp[pnum], vec3 pc[pnum]) {

 float grcnst = .3;
 vec2 force = vec2(0.);
 vec2 sp = vec2(0.);

  float d[pnum];

 for(int i = 0;i<ITER;i++){
  for(int j=0; j<pnum; j++){

   d[j] = distance(p, pp[j]);
     force += grcnst*(pp[j]-p)/(d[j]*d[j]);

    }

    p+= force;
  }

  vec3 result;
  float dmin = 10000.;
  int index =0;
  for(int i =0;i<pnum;i++){
   if(dmin>d[i]){
    dmin=d[i];
     index=i;
     }
  }

  result =pc[index];

 return result;
}

void main(void) {
 vec2 uv = gl_FragCoord.xy/resolution.xy;
 uv *= 2.0;
 uv -= 1.0;
 uv *= resolution.xy/min(resolution.x, resolution.y);

  uv *= 1.5;
  float tpos= (date.x + date.y + date.z + date.w)*.1 + 10.;
  float tcamzoom=(date.x + date.y + date.z + date.w)*.1 + 7.47;
  float tcampos = (date.x + date.y + date.z + date.w)*.1 + 7.47;
  float camzoom=.1+(1.+sin(tcamzoom))*.5;
  tcampos -= camzoom;
  uv *= camzoom;
  uv += camzoom * vec2(sin(tcampos), cos(tcampos));

  vec3 col = vec3(0.0);

  vec2 pp[pnum];
  pp[0] =
   vec2(0. + sin(tpos * 0.15), .5 + 2.* sin(tpos * .1));
  pp[1] =
   vec2(0. + .8* sin(tpos*.8),-.5 - 2.3*sin (tpos*.29));
  pp[2] =
   vec2(0.5+ .5 * sin(tpos * 0.39), -.5 + 1.3*sin(tpos * 0.7));
  //pp[3] = vec2(0.);
  vec3 pc[pnum];
  pc[0]= vec3(.3,.2,.4);
  pc[1]= vec3(.0,.6,.7);
  pc[2]= vec3(.3,.3,.6);
  //pc[3]=vec3(.0);

  vec3 mg = magnets(uv,pp,pc);
  col = mg;
  for(int i=0; i<pnum;i++){
   col = drawpoint(uv, pp[i], .03, col, pc[i]);
  }
 glFragColor = vec4(col, 1.0);
}
