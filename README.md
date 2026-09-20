# FURSYS 신규 거래처 Tracker — Admin + Dealer Portal

## 운영 구조
- **본사 관리자:** 로그인 화면에는 PIN만 입력합니다. 전체 거래처/히스토리 조회·수정, 대리점 배정, 포털 공개 ON/OFF, 대리점 계정 발급이 가능합니다.
- **대리점 포털:** 관리자가 발급한 `대리점 ID + PIN`으로 로그인합니다. DB의 RLS가 해당 대리점에 배정되고 `대리점 포털 공개=공개`인 업체만 반환합니다. 다른 대리점/미배정 업체는 조회할 수 없습니다.
- 대리점이 남긴 히스토리는 본사 관리자 화면에도 누적됩니다.

## 관리자 PIN
요청한 관리자 PIN은 **340062**입니다. 보안을 위해 HTML에 PIN 자체를 비교하는 코드는 넣지 않았습니다. Supabase Auth의 관리자 계정 비밀번호를 340062로 설정하고, 화면에서는 이메일을 숨겨 PIN만 받습니다.

> 중요: 6자리 PIN은 강한 인증수단은 아닙니다. 외부 인터넷에 공개된 GitHub Pages에서 실제 영업정보를 운영한다면 추후 관리자 PIN을 더 긴 비밀번호/MFA로 강화하는 것을 권장합니다.

## 1) Supabase
1. 새 Supabase 프로젝트 생성
2. SQL Editor에서 `schema.sql` 전체 실행
3. Authentication > Users에서 관리자 사용자 생성
   - Email: `admin@fursys-tracker.local`
   - Password: `340062`
   - Auto Confirm User: ON
4. SQL Editor에서 아래 SQL을 실행하되 `<ADMIN_USER_UUID>`는 방금 생성한 사용자의 UUID로 교체합니다.

```sql
insert into public.profiles(id,email,display_name,role,is_active)
values ('<ADMIN_USER_UUID>','admin@fursys-tracker.local','본사 관리자','admin',true);
```

5. Project Settings > API에서 Project URL과 anon/public key를 `config.js`에 입력합니다.

## 2) 대리점 계정 생성 Function
Supabase CLI에서:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy admin-dealers
```

관리자 로그인 후 `대리점 관리`에서 대리점명, 대리점 ID, PIN을 발급합니다. PIN은 생성 후 화면에 다시 표시하지 않습니다.

## 3) 업체 공개 방식
관리자가 업체의 `진행 대리점`을 대리점 계정의 **대리점명과 정확히 동일하게** 입력하고, `대리점 포털 공개`를 `공개`로 바꾸면 해당 대리점 포털에 나타납니다.

따라서 `진행 대리점`만 미리 적어놓고 공개는 꺼둘 수 있습니다. 대리점 선정 검토 단계와 실제 이관 단계를 분리할 수 있습니다.

## 4) GitHub Pages
`index.html`, `config.js`를 저장소 루트에 올리고 GitHub Pages를 활성화합니다. `supabase/` 폴더도 같이 버전관리해도 됩니다. service-role key는 절대 GitHub에 넣지 마세요.

## 5) 기존 발굴 데이터 이관
관리자 로그인 후 브라우저 개발자 콘솔에서 `seedData()`를 한 번 실행하면 기존 트래커의 업체/히스토리를 DB로 옮깁니다. 이미 업체 데이터가 있으면 중복 방지를 위해 중단됩니다.


## 로그인 버튼을 눌러도 반응이 없을 때
이 버전은 PIN을 HTML 안에서 비교하지 않습니다. `config.js`의 Supabase URL/anon key가 비어 있으면 로그인할 서버가 없기 때문에 관리자 PIN도 동작하지 않습니다. 이번 수정본에서는 이 경우 화면 하단에 **“아직 Supabase 연결 전입니다”**라는 안내가 표시됩니다.

관리자 PIN `340062`가 실제로 동작하려면 위 설치 순서대로 Supabase Auth에 `admin@fursys-tracker.local` 사용자를 만들고 비밀번호를 `340062`로 설정한 뒤 profiles 테이블에 admin 권한을 등록해야 합니다.
