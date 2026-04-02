#version 420

// original https://neort.io/art/c150b5k3p9f8fetmss3g

uniform vec2 resolution;
uniform float time;

out vec4 glFragColor;

float map(vec3 p)
{
  //p.x-=5.;
  p.z+=time*3.;
  p=mod(p,10.)-5.;
  for(int j=0;j<1;j++)
  {
    //折り曲げ
    p.xy=abs(p.xy);
    p.yz=abs(p.yz) - (sin(time*0.5)+1.0)*2.;
  }
   //crossで外積を求める
   return length(cross(p,vec3(-0.5,-0.5,-0.5)))-.1;
}

void main(){
    vec4 fragColor = vec4(0.0);
    //キャンパス設定と正規化
    vec2 uv=(gl_FragCoord.xy - 0.5*resolution)/resolution.y;
    vec3 rd=normalize(vec3(uv,1));
    
    //カメラの位置
    vec3 p=vec3(0,0,-5);
    
    //マーチングループ
    float d=1.,ix;
    for(int i=0;i<99;i++){
      p+=rd*(d=map(p));
      ix++;
      if (d<.001){break;}
    }
    
    //ヒットした部分を出力（iの値が低いと光る）
    for(int i=0;i<99;i++){
      p+=rd*(d=map(p));
      ix++;
      if (d<.001){break;}
    }
    if(d<.001) {
      fragColor += 5./ix;
      fragColor.y += 5.0/ix;
      fragColor.z += 0.3/ix;
    }
    glFragColor = fragColor;
    glFragColor.w = 1.0;    
    
}
