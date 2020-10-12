IF EXISTS ( SELECT * FROM sys.objects WHERE name = 'STP_NIF05NetOrderCancelIns' AND user_name(schema_id) = 'dbo' ) 
	DROP PROC STP_NIF05NetOrderCancelIns
GO
CREATE PROC STP_NIF05NetOrderCancelIns(
	@CustNo			INT							-- お客様番号					【パラメータ】
,	@OdrNo			BIGINT						-- 注文番号					【パラメータ】
,	@UserCd			VARCHAR(13)					-- ユーザコード					【共通パラメータ】
,	@UpdateJobMod	VARCHAR(80)					-- 更新ジョブ名					【共通パラメータ】
,	@Success		INT				OUTPUT		-- プロシージャの成否				【共通パラメータ】
,	@ErrCode		INT				OUTPUT		-- エラーコード					【共通パラメータ】
,	@ErrMsg			VARCHAR(250)	OUTPUT		-- エラーメッセージ				【共通パラメータ】
)
AS
/*
//---------------------------------------------------------------------------
//
//	System				: iWAOシステム
//	SP Name				: STP_NIF05NetOrderCancelIns
//	Overview			: NET注文キャンセル登録
//	Designer			: ChanhNV＠SSV
//	Programmer			: ChanhNV＠SSV
//	Created Date		: YYYY/MM/DD
//
//----------< Histroy >-----------------------------------------------------
//	ID					: 
//	Designer			: 
//	Programmer			: 
//	Updated Date		: 
//	Comment				: 
//	Version				: 
//----------< Histroy >-----------------------------------------------------
*/
BEGIN
	SET NOCOUNT ON
	/*
	bat  定数を
	 宣言する
	 co
	*/
	--########################################################################
	--## 定数を宣言する。															##
	--########################################################################
	DECLARE	-- 用定数
		@ct_Success_Success						INT				= 0								-- 処理成功
	,	@ct_Success_Error						INT				= 3								-- エラー
	,	@ct_ErrCode_Success						INT				= 0								-- エラーコード：エラー無し

	DECLARE	-- フラグ
		@ct_OnFlg								TINYINT			= 1								-- フラグ：オン
	,	@ct_OffFlg								TINYINT			= 0								-- フラグ：オフ

	DECLARE	-- 例外情報
		@ct_BusinessException					INT				= 16							-- 例外エラーパラメータ
	,	@ct_RaisErrorState						INT				= 1								-- 例外エラーステータス

	DECLARE	-- ストアドプロシージャ名
		@ct_ProcedureName						VARCHAR(80)		= 'STP_NIF05NetOrderCancelIns'	-- ストアドプロシージャ名

	DECLARE	-- メッセージ区分
		@ct_MsgKbn_BOT							CHAR(3)			= 'BOT'							-- 処理開始
	,	@ct_MsgKbn_EOT							CHAR(3)			= 'EOT'							-- 処理終了
	,	@ct_MsgKbn_INS							CHAR(3)			= 'INS'							-- 登録件数
	,	@ct_MsgKbn_UPD							CHAR(3)			= 'UPD'							-- 更新件数
	,	@ct_MsgKbn_MSG							CHAR(3)			= 'MSG'							-- メッセージ

	DECLARE -- アプリケーションメッセージコード
		@ct_MsgCd_BOT							VARCHAR(10)		= '110033'						-- 処理開始
	,	@ct_MsgCd_EOT							VARCHAR(10)		= '110034'						-- 処理終了
	,	@ct_MsgCd_INS							VARCHAR(10)		= '110041'						-- 登録件数
	,	@ct_MsgCd_UPD							VARCHAR(10)		= '110042'						-- 更新件数
	,	@ct_MsgCd_SelectErr						VARCHAR(10)		= '120127'						-- メッセージＣＤ：120127（*の取得に失敗しました。）

	DECLARE -- メッセージ
		@ct_ErrMsg_Key_CustNo					VARCHAR(20)		= 'CustNo = '					-- メッセージ：お客様番号
	,	@ct_ErrMsg_Key_OdrNo					VARCHAR(20)		= 'OdrNo = '					-- メッセージ：注文番号
	,	@ct_ErrMsg_Key_Sample					VARCHAR(20)		= 'Sample ='					-- メッセージ：サンプル
	,	@ct_ErrMsg_Key_AcrcvNo					VARCHAR(20)		= 'AcrcvNo ='					-- メッセージ：売掛番号

	DECLARE	-- STP_SYS_GetKey使用変数
		@ct_AddCnt								INT				= 1								-- 追加する数
	,	@ct_PointHistNoSeqKey					CHAR(10)		= '1005'						-- ポイント履歴番号
	,	@ct_ReturnNoSeqKey						CHAR(10)		= '1507'						-- 採番キー（返品番号）

	DECLARE	-- 処理結果
		@ct_RtnCd_ERR							INT				= -1							-- 処理結果
	,	@ct_ErrCd_SysSeq						VARCHAR(10)		= '310014'						-- エラーメッセージコード

	DECLARE -- 文字コード
		@ct_NullChar							VARCHAR(1)		= ''							-- 空文字
	,	@ct_TAB									VARCHAR(1)		= ''							-- TABコード
	,	@ct_IntZero								INT				= 0								-- ゼロ（数値）
	,	@ct_BigIntZero							BIGINT			= 0								-- ゼロ（数値）
	,	@ct_DecimalZero							DECIMAL			= 0								-- ゼロ（数値）
	,	@ct_IntOne								INT				= 1								-- いち（数値）
	,	@ct_LeftParenthes						VARCHAR(2)		= '【'							-- 【
	,	@ct_RightParenthes						VARCHAR(2)		= '】'							-- 】
	,	@ct_Colon								VARCHAR(1)		= ':'							-- :(コロン)

	DECLARE -- テーブル名
		@ct_TableName_CDynamicParameter			VARCHAR(100)	= '動的パラメータ制御'					-- 動的パラメータ制御
	,	@ct_TableName_FOdrH						VARCHAR(100)	= '注文伝票ヘダー'					-- 注文伝票ヘダー
	,	@ct_TableName_FOdrD						VARCHAR(100)	= '注文伝票明細'					-- 注文伝票明細
	,	@ct_TableName_FGuiNoH					VARCHAR(100)	= '統一発票伝票ヘダー'				-- 統一発票伝票ヘダー
	,	@ct_TableName_FShipAtt					VARCHAR(100)	= '発送注意伝票'					-- 発送注意伝票
	,	@ct_TableName_HCampgnGet				VARCHAR(100)	= '施策獲得履歴'					-- 施策獲得履歴
	,	@ct_TableName_MCustBal					VARCHAR(100)	= 'お客様残高台帳'					-- お客様残高台帳
	,	@ct_TableName_FAcrcvH					VARCHAR(100)	= '売掛伝票ヘダー'					-- 売掛伝票ヘダー
	,	@ct_TableName_FAcrcvD					VARCHAR(100)	= '売掛伝票明細'					-- 売掛伝票明細
	,	@ct_TableName_FAcrcvPayTerm				VARCHAR(100)	= '支払期限別売掛伝票明細'			-- 支払期限別売掛伝票明細
	,	@ct_TableName_MCustCredit				VARCHAR(100)	= 'お客様債権台帳'					-- お客様債権台帳
	,	@ct_TableName_MIntroCust				VARCHAR(100)	= '紹介者台帳'						-- 紹介者台帳
	,	@ct_TableName_HActualUpd				VARCHAR(100)	= '実績更新履歴'					-- 実績更新履歴
	,	@ct_TableName_HPoint					VARCHAR(100)	= 'ポイント履歴'						-- ポイント履歴
	,	@ct_TableName_FReturnH					VARCHAR(100)	= '返品伝票ヘダー'					-- 返品伝票ヘダー
	,	@ct_TableName_FReturnD					VARCHAR(100)	= '返品伝票明細'					-- 返品伝票明細
	,	@ct_TableName_HEraseReturn				VARCHAR(100)	= '抹消返品履歴'					-- 抹消返品履歴

	DECLARE-- カーソル名
		@ct_CursorName_HActualUpdData			VARCHAR(100)	='実績更新履歴'					-- 実績更新履歴
	,	@ct_CursorName_FReturnDData				VARCHAR(100)	='返品伝票明細'					-- 返品伝票明細

	DECLARE	-- 注文ヘダー状態
		@ct_ODRHDRSTAT_90						CHAR(2)			= '90'							-- 注文キャンセル

	DECLARE	-- 注文区分
		@ct_OrderKbn_1							CHAR(1)			= '1'							-- 1 : サンプル
	,	@ct_OrderKbn_2							CHAR(1)			= '2'							-- 2 : 注文
	/*
	ba la
	ma la
	*/
	DECLARE	-- 売上計上区分
		@ct_SalesSumUpKbn_1						CHAR(1)			= '1'							-- [売上計上区分]＝1(売掛作成済)
	,	@ct_SalesSumUpKbn_2						CHAR(1)			= '2'							-- [売上計上区分]＝2(売上計上済)
	,	@ct_SalesSumUpKbn_9						CHAR(1)			= '9'							-- [売上計上区分]＝9（売掛抹消）

	DECLARE	-- ポイント増減区分
		@ct_PointUpDownKbn_1					CHAR(1)			= '1'							-- [ポイント増減区分] = 1
	,	@ct_PointUpDownKbn_2					CHAR(1)			= '2'							-- [ポイント増減区分] = 2

	DECLARE	-- オブジェクト区分
		@ct_ObjKbn_01							CHAR(2)			= '01'							-- [オブジェクト区分] = 01

	DECLARE	-- オブジェクト区分
		@ct_PointOccurKbn_10					CHAR(2)			= '10'							-- [ポイント発生区分] = 10
	,	@ct_PointOccurKbn_20					CHAR(2)			= '20'							-- [ポイント発生区分] = 20

	DECLARE	-- 実績更新区分
		@ct_ActualUpdKbn_23						CHAR(2)			= '23'							-- [実績更新区分] = 23
	,	@ct_ActualUpdKbn_24						CHAR(2)			= '24'							-- [実績更新区分] = 24

	DECLARE	-- 赤黒区分
		@ct_RedKbn_2							CHAR(1)			= '2'							-- [赤黒区分] = 2

	DECLARE	-- 売上抹消区分
		@ct_SalesEraseKbn_2						CHAR(2)			= '01'							-- [売上抹消区分] = 01

	DECLARE	-- 返品確定状態
		@ct_ReturnFixStat_99					CHAR(2)			= '99'							-- [返品確定状態] = 99

	DECLARE -- 動的パラメータ
		@ct_DPara_PCd_ONLINEDATE				CHAR(5)			= '00003'						-- パラメータコード：オンライン日
	,	@ct_DPara_PKey_ONLINEDATE				VARCHAR(40)		= 'ONLINEDATE'					-- パラメータキー：オンライン日

	DECLARE -- 未設定値・初期値
		@ct_UnSetDtTm							DATETIME		= '1900/01/01'					-- 未設定日時
	,	@ct_ErrMsg_Get_NowDt					VARCHAR(100)	= 'オンライ日時を取得する'				-- オンライ日時を取得する
	,	@ct_ErrMsg_Get_InforOdr					VARCHAR(100)	= 'JとJU対象注文情報取得'			-- JとJU対象注文情報取得

	DECLARE --変数を定義する
		@w_ApplicationMessage					VARCHAR(250)									-- システムエラーメッセージ
	,	@w_MessageList							VARCHAR(6000)									-- メッセージ置換文字列
	, 	@w_MsgCd								CHAR(10)										-- メッセージコー ド

	DECLARE	--カウント変数を宣言する
		@w_FodrHUpdateCnt						INT				= 0								-- 更新した注文伝票ヘッダー件数
	,	@w_FodrDUpdateCnt						INT				= 0								-- 更新した注文伝票詳細件数
	,	@w_FGuiNoHUpdateCnt						INT				= 0								-- 更新した統一発票伝票ヘッダー件数
	,	@w_FShipAttUpdateCnt					INT				= 0								-- 更新した発票注意伝票件数
	,	@w_HCampgnGetUpdateCnt					INT				= 0								-- 更新した施策獲得履歴件数
	,	@w_MCustBalUpdateCnt					INT				= 0								-- 更新した施策獲得履歴件数
	,	@w_MIntroCustReqNoCnt					INT				= 0								-- 更新した紹介者台帳がある[被紹介者サンプル請求番号] = [注文コード]の件数
	,	@w_MIntroCustFirstOdrNoCnt				INT				= 0								-- 更新した紹介者台帳がある[被紹介者初回注文番号] = [注文コード]の件数
	,	@w_MIntroCustFavorOdrNoCnt				INT				= 0								-- 更新した紹介者台帳がある[紹介者特典注文番号] = [注文コード]の件数
	,	@w_HPointOccurPointNumInsertCnt			INT				= 0								-- 挿入した発生ポイントがあるポイント履歴件数
	,	@w_HPointUsePointNumInsertCnt			INT				= 0								-- 挿入した使用ポイントがあるポイント履歴件数
	,	@w_HActualHUpdInsertCnt					INT				= 0								-- 挿入したヘッダー部に実績更新履歴の件数
	,	@w_HActualDpdInsertCnt					INT				= 0								-- 挿入した明細部に実績更新履歴の件数
	,	@w_FReturnHInsertCnt					INT				= 0								-- 挿入した返品伝票ヘッダー件数
	,	@w_FReturnDInsertCnt					INT				= 0								-- 挿入した返品伝票詳細件数
	,	@w_FAcrcvHUpdateCnt						INT				= 0								-- 更新した売掛伝票ヘッダー件数
	,	@w_FAcrcvDUpdateCnt						INT				= 0								-- 更新した売掛伝票詳細件数
	,	@w_FAcrcvPayTermUpdateCnt				INT				= 0								-- 更新した支払期限による売掛伝票詳細件数
	,	@w_MCustCreditUpdateCnt					INT				= 0								-- 更新したお客様債権台帳件数
	,	@w_HEraseReturnInsertCnt				INT				= 0								-- 挿入した抹消返品履歴件数

	DECLARE	-- DB抽出結果保持変数
		@w_OdrHdrStat							CHAR(2)			= ''							-- <注文伝票ヘダー>.[注文状況フラグ]
	,	@w_SalesSumUpKbn						CHAR(1)			= ''							-- <注文伝票ヘダー>.[売上計上区分]
	,	@w_TotOccurPointNum						INT				= 0								-- <注文伝票ヘダー>.[合計発生ポイント数]
	,	@w_TotUsePointNum						INT				= 0								-- <注文伝票ヘダー>.[合計利用ポイント数]
	,	@w_OrderKbn								CHAR(1)			= ''							-- <注文伝票ヘダー>.[受注区分]
	,	@w_OdrAcptDtTm							DATETIME		= '1900/01/01'					-- <注文伝票ヘダー>.[注文受付時刻]
	,	@w_OdrRouteKbn							CHAR(2)			= ''							-- <注文伝票ヘダー>.[注文経路区分]
	,	@w_OdrOccurKbn							CHAR(2)			= ''							-- <注文伝票ヘダー>.[注文発生区分]
	,	@w_KekanKbn								CHAR(1)			= ''							-- <注文伝票ヘダー>.[化漢区分]
	,	@w_PayWayKbn							CHAR(2)			= ''							-- <注文伝票ヘダー>.[支払方法区分]
	,	@w_MediaCd								CHAR(8)			= ''							-- <注文伝票ヘダー>.[媒体コード]
	,	@w_CurrencyCd							CHAR(3)			= ''							-- <注文伝票ヘダー>.[通貨コード]
	,	@w_GiftFlg								TINYINT			= 0								-- <注文伝票ヘダー>.[ギフトフラグ]
	,	@w_GiftCustNo							INT				= 0								-- <注文伝票ヘダー>.[ギフトお客様番号]
	,	@w_GiftPointNum							INT				= 0								-- <注文伝票ヘダー>.[ギフトポイント数]

	DECLARE -- 売掛伝票ヘダー
		@w_FAcrcvH_SalesAmnt					DECIMAL(12,2)	= 0								-- <売掛伝票ヘダー>.[売上金額]
	,	@w_FAcrcvH_SalesTax						DECIMAL(12,2)	= 0								-- <売掛伝票ヘダー>.[売上消費税]
	,	@w_FAcrcvH_TotReturnAmnt				DECIMAL(12,2)	= 0								-- <売掛伝票ヘダー>.[合計返品金額]
	,	@w_FAcrcvH_ReturnAmnt					DECIMAL(12,2)	= 0								-- <売掛伝票ヘダー>.[返品金額]
	,	@w_FAcrcvH_ReturnTax					DECIMAL(12,2)	= 0								-- <売掛伝票ヘダー>.[返品消費税]
	,	@w_FAcrcvH_ReturnShipping				DECIMAL(12,2)	= 0								-- <売掛伝票ヘダー>.[返品送料]
	,	@w_FAcrcvH_ReturnShippingTax			DECIMAL(12,2)	= 0								-- <売掛伝票ヘダー>.[返品送料消費税]
	,	@w_FAcrcvH_ReturnFee					DECIMAL(12,2)	= 0								-- <売掛伝票ヘダー>.[返品手数料]
	,	@w_FAcrcvH_SalesFeeTax					DECIMAL(12,2)	= 0								-- <売掛伝票ヘダー>.[売上手数料消費税]
	,	@w_FAcrcvH_SalesSumUpDt					INT				= 0								-- <売掛伝票ヘダー>.[売上計上日付]

	DECLARE -- 注文伝票明細
		@w_FOdrD_OdrDtlNo						SMALLINT		= 0								-- <注文伝票明細>.[注文明細番号]
	,	@w_FOdrD_ItemCd							CHAR(5)			= ''							-- <注文伝票明細>.[商品コード]
	,	@w_FOdrD_ItemLvlCd						TINYINT			= 0								-- <注文伝票明細>.[商品レベルコード]
	,	@w_FOdrD_ItemKbn						CHAR(2)			= ''							-- <注文伝票明細>.[商品区分]
	,	@w_FOdrD_OpeDivCd						CHAR(2)			= ''							-- <注文伝票明細>.[事業部門コード]
	,	@w_FOdrD_ItemNum						SMALLINT		= 0								-- <注文伝票明細>.[商品数]
	,	@w_FOdrD_ItemPrice						DECIMAL(12,2)	= 0								-- <注文伝票明細>.[商品単価]
	,	@w_FOdrD_ItemPriceTax					DECIMAL(12,2)	= 0								-- <注文伝票明細>.[商品単価消費税]
	,	@w_FOdrD_TaxKbn							CHAR(1)			= ''							-- <注文伝票明細>.[]
	,	@w_FOdrD_TaxRateKbn						CHAR(1)			= ''							-- <注文伝票明細>.[]
	,	@w_FOdrD_OccurPointNum					INT				= 0								-- <注文伝票明細>.[発生ポイント数]
	,	@w_FOdrD_UsePointNum					INT				= 0								-- <注文伝票明細>.[利用ポイント数]

	DECLARE -- その他変数
		@w_NowDt								INT				= 0								-- 当日
	,	@w_NowTm								INT				= 0								-- 現在日時
	,	@w_NowDtTm								DATETIME		= '1900/01/01'					-- 現在日時
	,	@w_PointHistNo							BIGINT			= 0								-- ポイント履歴番号
	,	@w_ReturnNo								BIGINT			= 0								-- 現在時刻
	,	@w_BalPointNum							INT				= 0								-- 残ポイント数

	--########################################################################
	--## 出力パラメータの変数を初期化する。												##
	--########################################################################
	SET @Success							=	@ct_Success_Success
	SET @ErrCode							=	@ct_ErrCode_Success
	SET @ErrMsg								=	@ct_NullChar

	--########################################################################
	--## 変数を初期化する。														##
	--########################################################################
	SET @w_ApplicationMessage				=	@ct_NullChar
	SET @w_MessageList						=	@ct_NullChar
	SET	@w_MsgCd							=	@ct_NullChar

	--########################################################################
	--## メイン処理																##
	--########################################################################
	BEGIN TRY

		-- ジョブ実行開始をログ出力する
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_BOT, @ct_MsgCd_BOT, @ct_ProcedureName, @UpdateJobMod, @ct_ProcedureName, @UserCd 

		--=================================================================================
		-- 1.オンライ日時を取得する
		--=================================================================================
		-- 1．1[オンライ日付]を取得する
		-- 例外用エラーメッセージ編集
		SET	@w_MsgCd						=	@ct_MsgCd_SelectErr
		SET	@ErrMsg							=	@ct_TableName_CDynamicParameter + @ct_ErrMsg_Get_NowDt

		SELECT
			@w_NowDt						=	ISNULL(NumInfo1, @ct_IntZero)
		FROM
			CDynamicParameter WITH(NOLOCK)
		WHERE
			ParameterCd = @ct_DPara_PCd_ONLINEDATE
		AND
			ParameterKey = @ct_DPara_PKey_ONLINEDATE
		AND
			DelFlg = @ct_OffFlg
		OPTION (MAXDOP 1)

		IF @@ROWCOUNT = @ct_IntZero
		BEGIN
			-- エラーメッセージ編集
			EXECUTE FW_STP_GetApMessage @w_MsgCd, @ErrMsg, @w_ApplicationMessage OUTPUT
			-- 処理終了するためにエラー発生
			RAISERROR( @w_ApplicationMessage, @ct_BusinessException, @ct_RaisErrorState )
		END

		-- 1．2 [システム時刻]を取得する
		SELECT	@w_NowTm					=	CONVERT(INT, REPLACE( CONVERT(VARCHAR(8), GETDATE(), 108), @ct_Colon, @ct_NullChar) )
		-- 1．3	オンライン日時] = [オンライン日付] + [システム時刻]
		SET	@w_NowDtTm						=	dbo.FNC_NIF_GetDtTm(@w_NowDt, @w_NowTm)

		-- 例外用エラーメッセージ編集
		SET	@ErrMsg							=	@ct_TableName_FOdrH + @ct_ErrMsg_Get_InforOdr

		--=================================================================================
		-- 2.JとJU対象注文情報取得
		--=================================================================================
		-- 2.1注文伝票へダーから以下の項目を取得する。
		SELECT
			@w_OdrHdrStat					=	OdrHdrStat
		,	@w_SalesSumUpKbn				=	SalesSumUpKbn
		,	@w_TotOccurPointNum				=	TotOccurPointNum
		,	@w_TotUsePointNum				=	TotUsePointNum
		,	@w_OrderKbn						=	OrderKbn
		,	@w_OdrAcptDtTm					=	OdrAcptDtTm
		,	@w_OdrRouteKbn					=	OdrRouteKbn
		,	@w_OdrOccurKbn					=	OdrOccurKbn
		,	@w_KekanKbn						=	KekanKbn
		,	@w_PayWayKbn					=	PayWayKbn
		,	@w_MediaCd						=	MediaCd
		,	@w_CurrencyCd					=	CurrencyCd
		,	@w_GiftFlg						=	GiftFlg
		,	@w_GiftCustNo					=	GiftCustNo
		,	@w_GiftPointNum					=	GiftPointNum
		FROM
			FOdrH WITH(NOLOCK)
		WHERE
			OdrNo = @OdrNo
		AND
			DelFlg = @ct_OffFlg
		OPTION (MAXDOP 1)

		--=================================================================================
		-- 3. キャンセル注文を登録する
		--=================================================================================
		-- 3.1 以下のエンティティテーブルを更新する
		-- 3.1.1 注文伝票ヘダー更新
		-- エラーメッセージ編集
		SET	@ErrMsg							=	@ct_TableName_FOdrH + @ct_ErrMsg_Key_OdrNo
												+ CONVERT( VARCHAR, @OdrNo ) + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

		UPDATE
			FOdrH
		SET
			OdrHdrStat						=	@ct_ODRHDRSTAT_90
		,	SalesSumUpKbn					=	CASE SalesSumUpKbn
													WHEN	@ct_SalesSumUpKbn_1	THEN	@ct_SalesSumUpKbn_9
													ELSE	SalesSumUpKbn
												END
		,	UpdateUserCd					=	@UserCd
		,	UpdateWinDate					=	GETDATE()
		,	UpdateCount						=	dbo.FW_FNC_NextNo( UpdateCount )
		,	UpdateWinMod					=	@UpdateJobMod
		WHERE
			OdrNo = @OdrNo
		AND
			DelFlg = @ct_OffFlg

		-- 更新した注文伝票ヘッダー件数
		SET @w_FodrHUpdateCnt				+=	@@ROWCOUNT

		-- 3.1.2 注文伝票明細更新
		-- エラーメッセージ編集
		SET	@ErrMsg							=	@ct_TableName_FOdrD + @ct_ErrMsg_Key_OdrNo
												+ CONVERT( VARCHAR, @OdrNo ) + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

		UPDATE
			FOdrD
		SET
			OdrDtlStat						=	@ct_ODRHDRSTAT_90
		,	UpdateUserCd					=	@UserCd
		,	UpdateWinDate					=	GETDATE()
		,	UpdateCount						=	dbo.FW_FNC_NextNo( UpdateCount )
		,	UpdateWinMod					=	@UpdateJobMod
		WHERE
			OdrNo = @OdrNo
		AND
			DelFlg = @ct_OffFlg

		-- 更新した注文伝票詳細件数
		SET @w_FodrDUpdateCnt += @@ROWCOUNT

		-- 3.1.3 統一発表伝票へダー更新
		-- エラーメッセージ編集
		SET	@ErrMsg							=	@ct_TableName_FGuiNoH + @ct_ErrMsg_Key_OdrNo
												+ CONVERT( VARCHAR, @OdrNo ) + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

		UPDATE
			FGuiNoH
		SET
			ReturnDate						=	@w_NowDt
		,	AvailFlg						=	@ct_OffFlg
		,	InvalidReason					=	@ct_IntOne
		,	UpdateUserCd					=	@UserCd
		,	UpdateWinDate					=	GETDATE()
		,	UpdateCount						=	dbo.FW_FNC_NextNo( UpdateCount )
		,	UpdateWinMod					=	@UpdateJobMod
		WHERE
			OdrNo = @OdrNo
		AND
			AvailFlg = @ct_OnFlg
		AND
			DelFlg = @ct_OffFlg

		-- 更新した統一発票伝票ヘッダー件数
		SET	@w_FGuiNoHUpdateCnt				+=	@@ROWCOUNT

		-- 3.1.4 発送注意伝票更新
		-- エラーメッセージ編集
		SET	@ErrMsg							=	@ct_TableName_FShipAtt + @ct_ErrMsg_Key_OdrNo
												+ CONVERT( VARCHAR, @OdrNo ) + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

		UPDATE
			FShipAtt
		SET
			DelFlg							=	@ct_OnFlg
		,	UpdateUserCd					=	@UserCd
		,	UpdateWinDate					=	GETDATE()
		,	UpdateCount						=	dbo.FW_FNC_NextNo( UpdateCount )
		,	UpdateWinMod					=	@UpdateJobMod
		WHERE
			OdrNo = @OdrNo
		AND
			DelFlg = @ct_OffFlg

		-- 更新した発票注意伝票件数
		SET @w_FShipAttUpdateCnt			+=	@@ROWCOUNT

		-- 3.1.5 施策獲得履歴更新
		-- エラーメッセージ編集
		SET	@ErrMsg							=	@ct_TableName_HCampgnGet + @ct_ErrMsg_Key_OdrNo
												+ CONVERT( VARCHAR, @OdrNo ) + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

		UPDATE
			HCampgnGet
		SET
			DelFlg							=	@ct_OnFlg
		,	UpdateUserCd					=	@UserCd
		,	UpdateWinDate					=	GETDATE()
		,	UpdateCount						=	dbo.FW_FNC_NextNo( UpdateCount )
		,	UpdateWinMod					=	@UpdateJobMod
		WHERE
			OdrNo = @OdrNo
		AND
			DelFlg = @ct_OffFlg

		-- 更新した施策獲得履歴件数
		SET	@w_HCampgnGetUpdateCnt			+=	@@ROWCOUNT

		-- 3.1.6 お客様残高台帳更新
		SET	@ErrMsg							=	@ct_TableName_MCustBal + @ct_ErrMsg_Key_OdrNo
												+ CONVERT( VARCHAR, @OdrNo ) +  @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

		UPDATE
			MCustBal
		SET
			BalPointNum						=	BalPointNum - @w_TotOccurPointNum + @w_TotUsePointNum
		,	UpdateUserCd					=	@UserCd
		,	UpdateWinDate					=	GETDATE()
		,	UpdateCount						=	dbo.FW_FNC_NextNo( UpdateCount )
		,	UpdateWinMod					=	@UpdateJobMod
		WHERE
			CustNo = @CustNo
		AND
			DelFlg = @ct_OffFlg

		-- 更新した施策獲得履歴件数
		SET	@w_MCustBalUpdateCnt			+=	@@ROWCOUNT

		-- 3.1.7 紹介者台帳更新
		-- エラーメッセージ編集
		SET	@ErrMsg							=	@ct_TableName_MIntroCust + @ct_ErrMsg_Key_OdrNo
												+ CONVERT( VARCHAR, @OdrNo ) + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

		UPDATE
			MIntroCust
		SET
			IntroCustFromSmplReqNo			=	@ct_IntZero
		,	UpdateUserCd					=	@UserCd
		,	UpdateWinDate					=	GETDATE()
		,	UpdateCount						=	dbo.FW_FNC_NextNo( UpdateCount )
		,	UpdateWinMod					=	@UpdateJobMod
		WHERE
			CustNo = @CustNo
		AND
			IntroCustFromSmplReqNo = @OdrNo
		AND
			DelFlg = @ct_OffFlg

		-- 更新した紹介者台帳がある[被紹介者サンプル請求番号] = [注文コード]の件数
		SET	@w_MIntroCustReqNoCnt			+=	@@ROWCOUNT

		UPDATE
			MIntroCust
		SET
			IntroCustFromFirstOdrNo			=	@ct_IntZero
		,	UpdateUserCd					=	@UserCd
		,	UpdateWinDate					=	GETDATE()
		,	UpdateCount						=	dbo.FW_FNC_NextNo( UpdateCount )
		,	UpdateWinMod					=	@UpdateJobMod
		WHERE
			CustNo = @CustNo
		AND
			IntroCustSpecialFavorOdrNo = @OdrNo
		AND
			DelFlg = @ct_OffFlg

		-- 更新した紹介者台帳がある[被紹介者初回注文番号] = [注文コード]の件数
		SET	@w_MIntroCustFavorOdrNoCnt		+=	@@ROWCOUNT

		UPDATE
			MIntroCust
		SET
			IntroCustSpecialFavorOdrNo		=	@ct_IntZero
		,	IntroCustFromThankSendKbn		=	@ct_NullChar
		,	UpdateUserCd					=	@UserCd
		,	UpdateWinDate					=	GETDATE()
		,	UpdateCount						=	dbo.FW_FNC_NextNo( UpdateCount )
		,	UpdateWinMod					=	@UpdateJobMod
		WHERE
			CustNo = @CustNo
		AND
			IntroCustFromFirstOdrNo = @OdrNo
		AND
			DelFlg = @ct_OffFlg

		-- 更新した紹介者台帳がある[紹介者特典注文番号] = [注文コード]の件数
		SET	@w_MIntroCustFirstOdrNoCnt		+=	@@ROWCOUNT

		-- 3.1.8 ポイント履歴登録
		-- エラーメッセージ編集
		SET	@ErrMsg							=	@ct_TableName_HPoint + @ct_ErrMsg_Key_OdrNo
												+ CONVERT( VARCHAR, @OdrNo ) + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

		-- 残ポイント数を取得する
		SELECT TOP 1
			@w_BalPointNum					=	BalPointNum
		FROM
			HPoint WITH(NOLOCK)
		WHERE
			CustNo = @CustNo
		AND
			DelFlg = @ct_OffFlg
		ORDER BY 
			PointOccurDtTm DESC
		OPTION (MAXDOP 1)

		-- 3.1.8.1 [合計発生ポイント](2で取得した) > 0の場合
		IF	@w_TotOccurPointNum > @ct_IntZero
		BEGIN
			-- ポイント履歴番号を取得する
			EXECUTE STP_SYS_GetKey @ct_AddCnt, @ct_PointHistNoSeqKey, @w_PointHistNo OUTPUT, @ErrCode OUTPUT, @ErrMsg OUTPUT

			IF @ErrCode <> @ct_Success_Success
			BEGIN
				SET @Success				=	@ct_RtnCd_ERR
				SET @w_MsgCd				=	@ct_ErrCd_SysSeq
				SET @ErrMsg					=	@ct_PointHistNoSeqKey
				EXECUTE FW_STP_GetApMessage @w_MsgCd, @ErrMsg, @w_ApplicationMessage OUTPUT
				-- 処理終了するためにエラー発生
				RAISERROR( @w_ApplicationMessage, @ct_BusinessException, @ct_RaisErrorState )
			END

			INSERT	INTO	HPoint
			(
				PointHistNo											-- ポイント履歴番号
			,	CustNo												-- お客様番号
			,	PointUpDownNum										-- ポイント増減数
			,	PointUpDownKbn										-- ポイント増減区分
			,	PointOccurDtTm										-- ポイント発生日時
			,	ObjNo												-- オブジェクト番号
			,	ObjKbn												-- オブジェクト区分
			,	CampgnGrpCd											-- 施策グループコード
			,	CampgnCd											-- 施策コード
			,	PointOccurKbn										-- ポイント発生区分
			,	PointOccurRsnMemo									-- ポイント発生理由メモ
			,	BalPointNum											-- 残ポイント数
			,	BalPointAvailTermDt									-- 残ポイント有効期限年月日
			,	RegisterUserCd										-- 登録ユーザコード
			,	RegisterDate										-- 登録日時
			,	UpdateUserCd										-- 更新ユーザコード
			,	UpdateWinDate										-- 画面更新日時
			,	UpdateJobDate										-- バッチ更新日時
			,	UpdateCount											-- 更新カウント
			,	UpdateWinMod										-- 更新画面名
			,	UpdateJobMod										-- 更新バッチ名
			,	DelFlg												-- 論理削除フラグ
			)
			VALUES
			(
				@w_PointHistNo										-- ポイント履歴番号
			,	@CustNo												-- お客様番号
			,	@w_TotOccurPointNum * -@ct_IntOne					-- ポイント増減数
			,	@ct_PointUpDownKbn_1								-- ポイント増減区分
			,	@w_NowDtTm											-- ポイント発生日時
			,	@OdrNo												-- オブジェクト番号
			,	@ct_ObjKbn_01										-- オブジェクト区分
			,	@ct_NullChar										-- 施策グループコード
			,	@ct_NullChar										-- 施策コード
			,	@ct_PointOccurKbn_10								-- ポイント発生区分
			,	@ct_NullChar										-- ポイント発生理由メモ
			,	@w_BalPointNum - @w_TotOccurPointNum				-- 残ポイント数
			,	@ct_IntZero											-- 残ポイント有効期限年月日
			,	@UserCd												-- 登録ユーザコード
			,	GETDATE()											-- 登録日時
			,	@UserCd												-- 更新ユーザコード
			,	GETDATE()											-- 画面更新日時
			,	GETDATE()											-- バッチ更新日時
			,	@ct_IntZero											-- 更新カウント
			,	@UpdateJobMod										-- 更新画面名
			,	@ct_NullChar										-- 更新バッチ名
			,	@ct_OffFlg											-- 論理削除フラグ
			)

			-- 挿入した発生ポイントがあるポイント履歴件数
			SET	@w_HPointOccurPointNumInsertCnt	+=	@@ROWCOUNT
		END

		-- 3.1.8.2 [合計使用ポイント数](2で取得した) > 0の場合
		IF	@w_TotUsePointNum > @ct_IntZero
		BEGIN
			-- ポイント履歴番号を取得する
			EXECUTE STP_SYS_GetKey @ct_AddCnt, @ct_PointHistNoSeqKey, @w_PointHistNo OUTPUT, @ErrCode OUTPUT, @ErrMsg OUTPUT

			IF	@ErrCode <> @ct_Success_Success
			BEGIN
				SET @Success				=	@ct_RtnCd_ERR
				SET @w_MsgCd				=	@ct_ErrCd_SysSeq
				SET @ErrMsg					=	@ct_PointHistNoSeqKey
				EXECUTE FW_STP_GetApMessage @w_MsgCd, @ErrMsg, @w_ApplicationMessage OUTPUT
				-- 処理終了するためにエラー発生
				RAISERROR( @w_ApplicationMessage, @ct_BusinessException, @ct_RaisErrorState )
			END

			INSERT	INTO	HPoint
			(
				PointHistNo											-- ポイント履歴番号
			,	CustNo												-- お客様番号
			,	PointUpDownNum										-- ポイント増減数
			,	PointUpDownKbn										-- ポイント増減区分
			,	PointOccurDtTm										-- ポイント発生日時
			,	ObjNo												-- オブジェクト番号
			,	ObjKbn												-- オブジェクト区分
			,	CampgnGrpCd											-- 施策グループコード
			,	CampgnCd											-- 施策コード
			,	PointOccurKbn										-- ポイント発生区分
			,	PointOccurRsnMemo									-- ポイント発生理由メモ
			,	BalPointNum											-- 残ポイント数
			,	BalPointAvailTermDt									-- 残ポイント有効期限年月日
			,	RegisterUserCd										-- 登録ユーザコード
			,	RegisterDate										-- 登録日時
			,	UpdateUserCd										-- 更新ユーザコード
			,	UpdateWinDate										-- 画面更新日時
			,	UpdateJobDate										-- バッチ更新日時
			,	UpdateCount											-- 更新カウント
			,	UpdateWinMod										-- 更新画面名
			,	UpdateJobMod										-- 更新バッチ名
			,	DelFlg												-- 論理削除フラグ
			)
			VALUES
			(
				@w_PointHistNo										-- ポイント履歴番号
			,	@CustNo												-- お客様番号
			,	@w_TotUsePointNum * -@ct_IntOne						-- ポイント増減数
			,	@ct_PointUpDownKbn_2								-- ポイント増減区分
			,	@w_NowDtTm											-- ポイント発生日時
			,	@OdrNo												-- オブジェクト番号
			,	@ct_ObjKbn_01										-- オブジェクト区分
			,	@ct_NullChar										-- 施策グループコード
			,	@ct_NullChar										-- 施策コード
			,	@ct_PointOccurKbn_20								-- ポイント発生区分
			,	@ct_NullChar										-- ポイント発生理由メモ
			,	@w_TotOccurPointNum * -@ct_IntOne					-- 残ポイント数
			,	@ct_IntZero											-- 残ポイント有効期限年月日
			,	@UserCd												-- 登録ユーザコード
			,	GETDATE()											-- 登録日時
			,	@UserCd												-- 更新ユーザコード
			,	GETDATE()											-- 画面更新日時
			,	GETDATE()											-- バッチ更新日時
			,	@ct_IntZero											-- 更新カウント
			,	@UpdateJobMod										-- 更新画面名
			,	@ct_NullChar										-- 更新バッチ名
			,	@ct_OffFlg											-- 論理削除フラグ
			)

			-- 挿入した使用ポイントがあるポイント履歴件数
			SET	@w_HPointUsePointNumInsertCnt	+=	@@ROWCOUNT
		END

		-- 3.1.10 実績更新履歴登録
		-- 3.1.10.1 以下のようにヘダーレコードを登録する
		-- エラーメッセージ編集
		SET	@ErrMsg							=	@ct_TableName_HActualUpd + @ct_ErrMsg_Key_OdrNo
												+ CONVERT( VARCHAR, @OdrNo ) + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

		INSERT	INTO	HActualUpd									-- 実績更新履歴
		(
			ActualUpdKbn											-- 実績更新区分
		,	SumUpDtTm												-- 計上日時
		,	ActualUpdDtTm											-- 実績更新日時
		,	CustNo													-- お客様番号
		,	SmplReqNo												-- サンプル請求番号
		,	SmplReqDtlNo											-- サンプル請求明細番号
		,	OdrNo													-- 注文番号
		,	OdrDtlNo												-- 注文明細番号
		,	SmplShipNo												-- サンプル発送番号
		,	SmplShipDtlNo											-- サンプル発送明細番号
		,	ShipNo													-- 発送番号
		,	ShipDtlNo												-- 発送明細番号
		,	ReturnNo												-- 返品番号
		,	ReturnDtlNo												-- 返品明細番号
		,	SmplReqRouteKbn											-- サンプル請求経路区分
		,	OdrRouteKbn												-- 注文経路区分
		,	OdrOccurKbn												-- 注文発生区分
		,	KekanKbn												-- 化漢区分
		,	PayWayKbn												-- 支払方法区分
		,	MediaCd													-- 媒体コード
		,	ItemCd													-- 商品コード
		,	ItemLvlCd												-- 商品レベルコード
		,	ItemKbn													-- 商品区分
		,	OpeDivCd												-- 事業部門コード
		,	ItemNum													-- 商品数
		,	CurrencyCd												-- 通貨コード
		,	ItemPrice												-- 商品単価
		,	ItemPriceTax											-- 商品単価消費税
		,	OccurPointNum											-- 発生ポイント数
		,	UsePointNum												-- 利用ポイント数
		,	GiftFlg													-- ギフトフラグ
		,	GiftCustNo												-- ギフトお客様番号
		,	GiftPointNum											-- ギフトポイント数
		,	RedKbn													-- 赤黒区分
		,	SumUpKbn1												-- 計上区分1
		,	SumUpKbn2												-- 計上区分2
		,	SumUpKbn3												-- 計上区分3
		,	SumUpKbn4												-- 計上区分4
		,	SumUpKbn5												-- 計上区分5
		,	RegisterUserCd											-- 登録ユーザコード
		,	RegisterDate											-- 登録日時
		,	UpdateUserCd											-- 更新ユーザコード
		,	UpdateWinDate											-- 画面更新日時
		,	UpdateJobDate											-- バッチ更新日時
		,	UpdateCount												-- 更新カウント
		,	UpdateWinMod											-- 更新画面名
		,	UpdateJobMod											-- 更新バッチ名
		,	DelFlg													-- 論理削除フラグ
		)
		VALUES
		(
			@ct_ActualUpdKbn_23										-- [入力パラメータ].[実績更新区分]
		,	@w_OdrAcptDtTm											-- [入力パラメータ].[計上日時]
		,	@w_NowDtTm												-- [内部変数].[実績更新日時]
		,	@CustNo													-- [入力パラメータ].[お客様番号]
		,	@ct_IntZero												-- [内部変数].[サンプル請求番号]
		,	@ct_IntZero												-- [内部変数].[サンプル請求明細番号]
		,	@OdrNo													-- [内部変数].[注文番号]
		,	@ct_IntZero												-- [内部変数].[注文明細番号]
		,	@ct_IntZero												-- [内部変数].[サンプル発送番号]
		,	@ct_IntZero												-- [内部変数].[サンプル発送明細番号]
		,	@ct_IntZero												-- [内部変数].[発送番号]
		,	@ct_IntZero												-- [内部変数].[発送明細番号]
		,	@ct_IntZero												-- [内部変数].[返品番号]
		,	@ct_IntZero												-- [内部変数].[返品明細番号]
		,	@ct_NullChar											-- [内部変数].[サンプル請求経路区分]
		,	@w_OdrRouteKbn											-- [内部変数].[注文経路区分]
		,	@w_OdrOccurKbn											-- [内部変数].[注文発生区分]
		,	@w_KekanKbn												-- [内部変数].[化漢区分]
		,	@w_PayWayKbn											-- [内部変数].[支払方法区分]
		,	@w_MediaCd												-- [内部変数].[媒体コード]
		,	@ct_NullChar											-- [内部変数].[商品コード]
		,	@ct_IntZero												-- [内部変数].[商品レベルコード]
		,	@ct_NullChar											-- [内部変数].[商品区分]
		,	@ct_NullChar											-- [内部変数].[事業部門コード]
		,	@ct_IntZero												-- [内部変数].[商品数]
		,	@w_CurrencyCd											-- [内部変数].[通貨コード]
		,	@ct_IntZero												-- [内部変数].[商品単価]
		,	@ct_IntZero												-- [内部変数].[商品単価消費税]
		,	@w_TotOccurPointNum										-- [内部変数].[発生ポイント数]
		,	@w_TotUsePointNum										-- [内部変数].[利用ポイント数]
		,	@w_GiftFlg												-- [内部変数].[ギフトフラグ]
		,	@w_GiftCustNo											-- [内部変数].[ギフトお客様番号]
		,	@w_GiftPointNum											-- [内部変数].[ギフトポイント数]
		,	@ct_RedKbn_2											-- [内部変数].[赤黒区分]
		,	@ct_NullChar											-- 初期値
		,	@ct_NullChar											-- 初期値
		,	@ct_NullChar											-- 初期値
		,	@ct_NullChar											-- 初期値
		,	@ct_NullChar											-- 初期値
		,	@UserCd													-- [入力パラメータ].[ユーザコード]
		,	GETDATE()												-- システム日時
		,	@UserCd													-- [入力パラメータ].[ユーザコード]
		,	GETDATE()												-- システム日時
		,	GETDATE()												-- システム日時
		,	@ct_IntZero												-- 0
		,	@UpdateJobMod											-- ブランク
		,	@ct_NullChar											-- [入力パラメータ].[更新ジョブ名]
		,	@ct_IntZero												-- 0(非削除)
		)

		-- 挿入したヘッダー部に実績更新履歴の件数
		SET	@w_HActualHUpdInsertCnt			+=	@@ROWCOUNT

		-- 3.1.10.2 明細レコードを登録する
		-- 例外用エラーメッセージ編集
		SET	@ErrMsg							=	@ct_CursorName_HActualUpdData +	@ct_ErrMsg_Key_OdrNo + CONVERT( VARCHAR, @OdrNo )

		DECLARE c_HActualUpdData CURSOR FAST_FORWARD FOR
			SELECT
				OdrDtlNo
			,	ItemCd
			,	ItemLvlCd
			,	ItemKbn
			,	OpeDivCd
			,	ItemNum
			,	ItemPrice
			,	ItemPriceTax
			,	OccurPointNum
			,	UsePointNum
			FROM
				FOdrD WITH(NOLOCK)
			WHERE
				OdrNo = @OdrNo
			AND
				DelFlg = @ct_OffFlg
			ORDER BY
				OdrDtlNo
			OPTION (MAXDOP 1)

		---------------------------------
		-- 注文伝票明細カーソルオープン
		---------------------------------
		--カーソルOPEN
		OPEN　c_HActualUpdData

		---------------------------------
		-- 注文伝票明細カーソルフェッチ
		---------------------------------
		-- 例外用エラーメッセージ編集
		SET	@ErrMsg							=	@ct_CursorName_HActualUpdData	+	@ct_ErrMsg_Key_OdrNo + CONVERT( VARCHAR, @OdrNo )

		FETCH NEXT FROM c_HActualUpdData INTO
			@w_FOdrD_OdrDtlNo													-- <注文伝票明細>.[注文明細番号]
		,	@w_FOdrD_ItemCd														-- <注文伝票明細>.[商品コード]
		,	@w_FOdrD_ItemLvlCd													-- <注文伝票明細>.[商品レベルコード]
		,	@w_FOdrD_ItemKbn													-- <注文伝票明細>.[商品区分]
		,	@w_FOdrD_OpeDivCd													-- <注文伝票明細>.[事業部門コード]
		,	@w_FOdrD_ItemNum													-- <注文伝票明細>.[商品数]
		,	@w_FOdrD_ItemPrice													-- <注文伝票明細>.[商品単価]
		,	@w_FOdrD_ItemPriceTax												-- <注文伝票明細>.[商品単価消費税]
		,	@w_FOdrD_OccurPointNum												-- <注文伝票明細>.[発生ポイント数]
		,	@w_FOdrD_UsePointNum												-- <注文伝票明細>.[利用ポイント数]

		---------------------------------------------------------
		-- カーソルで取得した行が終端に達するまで処理を継続する
		---------------------------------------------------------
		WHILE ( @@FETCH_STATUS = @ct_IntZero )
		BEGIN
			-- [Kbn Order] (2で取得した) = '1'の場合、[Error message] = 'コンタクト履歴' + 'Sample =' + '[注文番号]' + 'CustNo = ' + '[お客様番号]'　とする。
			IF @w_OrderKbn = @ct_OrderKbn_1
			BEGIN
				SET	@ErrMsg					=	@ct_TableName_HActualUpd + @ct_ErrMsg_Key_Sample
												+ CONVERT( VARCHAR, @OdrNo ) +  @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )
			END
			-- [Kbn Order] (2で取得した) = '2'の場合、[Error message] = 'コンタクト履歴' + 'OdrNo =' + '[注文番号]' + 'CustNo = ' + '[お客様番号]'　とする。
			ELSE IF @w_OrderKbn = @ct_OrderKbn_2
			BEGIN
				SET	@ErrMsg					=	@ct_TableName_HActualUpd + @ct_ErrMsg_Key_OdrNo
												+ CONVERT( VARCHAR, @OdrNo ) + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )
			END

			INSERT INTO HActualUpd										-- 実績更新履歴
			(
				ActualUpdKbn											-- 実績更新区分
			,	SumUpDtTm												-- 計上日時
			,	ActualUpdDtTm											-- 実績更新日時
			,	CustNo													-- お客様番号
			,	SmplReqNo												-- サンプル請求番号
			,	SmplReqDtlNo											-- サンプル請求明細番号
			,	OdrNo													-- 注文番号
			,	OdrDtlNo												-- 注文明細番号
			,	SmplShipNo												-- サンプル発送番号
			,	SmplShipDtlNo											-- サンプル発送明細番号
			,	ShipNo													-- 発送番号
			,	ShipDtlNo												-- 発送明細番号
			,	ReturnNo												-- 返品番号
			,	ReturnDtlNo												-- 返品明細番号
			,	SmplReqRouteKbn											-- サンプル請求経路区分
			,	OdrRouteKbn												-- 注文経路区分
			,	OdrOccurKbn												-- 注文発生区分
			,	KekanKbn												-- 化漢区分
			,	PayWayKbn												-- 支払方法区分
			,	MediaCd													-- 媒体コード
			,	ItemCd													-- 商品コード
			,	ItemLvlCd												-- 商品レベルコード
			,	ItemKbn													-- 商品区分
			,	OpeDivCd												-- 事業部門コード
			,	ItemNum													-- 商品数
			,	CurrencyCd												-- 通貨コード
			,	ItemPrice												-- 商品単価
			,	ItemPriceTax											-- 商品単価消費税
			,	OccurPointNum											-- 発生ポイント数
			,	UsePointNum												-- 利用ポイント数
			,	GiftFlg													-- ギフトフラグ
			,	GiftCustNo												-- ギフトお客様番号
			,	GiftPointNum											-- ギフトポイント数
			,	RedKbn													-- 赤黒区分
			,	SumUpKbn1												-- 計上区分1
			,	SumUpKbn2												-- 計上区分2
			,	SumUpKbn3												-- 計上区分3
			,	SumUpKbn4												-- 計上区分4
			,	SumUpKbn5												-- 計上区分5
			,	RegisterUserCd											-- 登録ユーザコード
			,	RegisterDate											-- 登録日時
			,	UpdateUserCd											-- 更新ユーザコード
			,	UpdateWinDate											-- 画面更新日時
			,	UpdateJobDate											-- バッチ更新日時
			,	UpdateCount												-- 更新カウント
			,	UpdateWinMod											-- 更新画面名
			,	UpdateJobMod											-- 更新バッチ名
			,	DelFlg													-- 論理削除フラグ
			)
			VALUES
			(
				@ct_ActualUpdKbn_24										-- [入力パラメータ].[実績更新区分]
			,	@w_OdrAcptDtTm											-- [入力パラメータ].[計上日時]
			,	@w_NowDtTm												-- [内部変数].[実績更新日時]
			,	@CustNo													-- [入力パラメータ].[お客様番号]
			,	@ct_IntZero												-- [内部変数].[サンプル請求番号]
			,	@ct_IntZero												-- [内部変数].[サンプル請求明細番号]
			,	@OdrNo													-- [内部変数].[注文番号]
			,	@w_FOdrD_OdrDtlNo										-- [内部変数].[注文明細番号]
			,	@ct_IntZero												-- [内部変数].[サンプル発送番号]
			,	@ct_IntZero												-- [内部変数].[サンプル発送明細番号]
			,	@ct_IntZero												-- [内部変数].[発送番号]
			,	@ct_IntZero												-- [内部変数].[発送明細番号]
			,	@ct_IntZero												-- [内部変数].[返品番号]
			,	@ct_IntZero												-- [内部変数].[返品明細番号]
			,	@ct_NullChar											-- [内部変数].[サンプル請求経路区分]
			,	@w_OdrRouteKbn											-- [内部変数].[注文経路区分]
			,	@w_OdrOccurKbn											-- [内部変数].[注文発生区分]
			,	@w_KekanKbn												-- [内部変数].[化漢区分]
			,	@w_PayWayKbn											-- [内部変数].[支払方法区分]
			,	@w_MediaCd												-- [内部変数].[媒体コード]
			,	@w_FOdrD_ItemCd											-- [内部変数].[商品コード]
			,	@w_FOdrD_ItemLvlCd										-- [内部変数].[商品レベルコード]
			,	@w_FOdrD_ItemKbn										-- [内部変数].[商品区分]
			,	@w_FOdrD_OpeDivCd										-- [内部変数].[事業部門コード]
			,	@w_FOdrD_ItemNum										-- [内部変数].[商品数]
			,	@w_CurrencyCd											-- [内部変数].[通貨コード]
			,	@w_FOdrD_ItemPrice										-- [内部変数].[商品単価]
			,	@w_FOdrD_ItemPriceTax									-- [内部変数].[商品単価消費税]
			,	@w_FOdrD_OccurPointNum									-- [内部変数].[発生ポイント数]
			,	@w_FOdrD_UsePointNum									-- [内部変数].[利用ポイント数]
			,	@w_GiftFlg												-- [内部変数].[ギフトフラグ]
			,	@w_GiftCustNo											-- [内部変数].[ギフトお客様番号]
			,	@w_GiftPointNum											-- [内部変数].[ギフトポイント数]
			,	@ct_RedKbn_2											-- [内部変数].[赤黒区分]
			,	@ct_NullChar											-- [内部変数].[計上区分1]
			,	@ct_NullChar											-- [内部変数].[計上区分2]
			,	@ct_NullChar											-- [内部変数].[計上区分3]
			,	@ct_NullChar											-- [内部変数].[計上区分4]
			,	@ct_NullChar											-- [内部変数].[計上区分5]
			,	@UserCd													-- [入力パラメータ].[ユーザコード]
			,	GETDATE()												-- システム日時
			,	@UserCd													-- [入力パラメータ].[ユーザコード]
			,	GETDATE()												-- システム日時
			,	GETDATE()												-- システム日時
			,	@ct_IntZero												-- 0
			,	@UpdateJobMod											-- ブランク
			,	@ct_NullChar											-- [入力パラメータ].[更新ジョブ名]
			,	@ct_IntZero												-- 0(非削除)
			)

			-- 挿入した明細部に実績更新履歴の件数
			SET	@w_HActualDpdInsertCnt		+=	@@ROWCOUNT

			---------------------------------
			-- 注文伝票明細カーソルフェッチ
			---------------------------------
			SET	@ErrMsg						=	@ct_CursorName_HActualUpdData + @ct_ErrMsg_Key_OdrNo + CONVERT( VARCHAR, @OdrNo )

			FETCH NEXT FROM c_HActualUpdData INTO
				@w_FOdrD_OdrDtlNo												-- <注文伝票明細>.[注文明細番号]
			,	@w_FOdrD_ItemCd													-- <注文伝票明細>.[商品コード]
			,	@w_FOdrD_ItemLvlCd												-- <注文伝票明細>.[商品レベルコード]
			,	@w_FOdrD_ItemKbn												-- <注文伝票明細>.[商品区分]
			,	@w_FOdrD_OpeDivCd												-- <注文伝票明細>.[事業部門コード]
			,	@w_FOdrD_ItemNum												-- <注文伝票明細>.[商品数]
			,	@w_FOdrD_ItemPrice												-- <注文伝票明細>.[商品単価]
			,	@w_FOdrD_ItemPriceTax											-- <注文伝票明細>.[商品単価消費税]
			,	@w_FOdrD_OccurPointNum											-- <注文伝票明細>.[発生ポイント数]
			,	@w_FOdrD_UsePointNum											-- <注文伝票明細>.[利用ポイント数]
		END

		-- カーソル解放処理
		EXECUTE FW_STP_DisposeCursor NULL, 'c_HActualUpdData', @UpdateJobMod, @UserCd, @Success OUTPUT

		-- 3.2　[売上集計区分] (2で取得した) = '2'の場合、引き続き以下のエンティティテーブルを登録・更新する。
		IF	@w_SalesSumUpKbn = @ct_SalesSumUpKbn_2
		BEGIN
			-- 3.2.1　売掛伝票へダー更新
			-- エラーメッセージ編集
			SET	@ErrMsg						=	@ct_TableName_FAcrcvH + @ct_ErrMsg_Key_AcrcvNo
												+  CONVERT( VARCHAR, @OdrNo ) + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )
			-- 3.2.1.1 売掛伝票へダーから以下の項目を取得する
			SELECT
				@w_FAcrcvH_SalesAmnt		=	SalesAmnt
			,	@w_FAcrcvH_SalesTax			=	SalesTax
			FROM
				FAcrcvH WITH(NOLOCK)
			WHERE
				OdrNo = @OdrNo
			AND
				DelFlg = @ct_OffFlg
			OPTION (MAXDOP 1)

			IF @@ROWCOUNT					=	@ct_IntZero
			BEGIN
				-- <売掛伝票ヘダー>.[売上金額]
				SET	@w_FAcrcvH_SalesAmnt	=	@ct_IntZero
				-- <売掛伝票ヘダー>.[売上消費税]
				SET	@w_FAcrcvH_SalesTax		=	@ct_IntZero
			END

			UPDATE
				FAcrcvH
			SET
				ReturnAmnt					=	@w_FAcrcvH_SalesAmnt
			,	ReturnTax					=	@w_FAcrcvH_SalesTax
			,	TotReturnAmnt				=	@w_FAcrcvH_SalesAmnt + @w_FAcrcvH_SalesTax
			,	AcrcvBalAmnt				=	AcrcvBalAmnt - @w_FAcrcvH_SalesAmnt - @w_FAcrcvH_SalesTax
			,	LastReturnDt				=	@w_NowDt
			,	UpdateUserCd				=	@UserCd
			,	UpdateWinDate				=	GETDATE()
			,	UpdateCount					=	dbo.FW_FNC_NextNo( UpdateCount )
			,	UpdateWinMod				=	@UpdateJobMod
			WHERE
				OdrNo = @OdrNo
			AND
				DelFlg = @ct_OffFlg

			-- 更新した売掛伝票ヘッダー件数
			SET	@w_FAcrcvHUpdateCnt			+=	@@ROWCOUNT

			-- 3.2.2 売掛伝票明細更新
			-- エラーメッセージ編集
			SET	@ErrMsg						=	@ct_TableName_FAcrcvD + @ct_ErrMsg_Key_AcrcvNo
											+ CONVERT( VARCHAR, @OdrNo ) + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

			UPDATE
				FAcrcvD
			SET
				ReturnNum					=	SalesNum
			,	ReturnPrice					=	SalesPrice
			,	ReturnAmnt					=	SalesAmnt
			,	ReturnTax					=	SalesTax
			,	UpdateUserCd				=	@UserCd
			,	UpdateWinDate				=	GETDATE()
			,	UpdateCount					=	dbo.FW_FNC_NextNo( UpdateCount )
			,	UpdateWinMod				=	@UpdateJobMod
			WHERE
				OdrNo = @OdrNo
			AND
				DelFlg = @ct_OffFlg

			-- 更新した売掛伝票詳細件数
			SET	@w_FAcrcvDUpdateCnt			+=	@@ROWCOUNT

			-- 3.2.3 支払期限別売掛伝票明細更新
			-- エラーメッセージ編集
			SET	@ErrMsg						=	@ct_TableName_FAcrcvPayTerm + @ct_ErrMsg_Key_AcrcvNo
												+ CONVERT( VARCHAR, @OdrNo ) + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

			UPDATE
				FAcrcvPayTerm
			SET
				ReturnAssignAmnt			=	@w_FAcrcvH_SalesAmnt + @w_FAcrcvH_SalesTax
			,	UpdateUserCd				=	@UserCd
			,	UpdateWinDate				=	GETDATE()
			,	UpdateCount					=	dbo.FW_FNC_NextNo( UpdateCount )
			,	UpdateWinMod				=	@UpdateJobMod
			WHERE
				AcrcvNo = @OdrNo
			AND
				DelFlg = @ct_OffFlg

			-- 更新した支払期限による売掛伝票詳細件数
			SET @w_FAcrcvPayTermUpdateCnt	+=	@@ROWCOUNT

			-- 3.2.4 お客様債権台帳更新
			-- エラーメッセージ編集
			SET	@ErrMsg						=	@ct_TableName_MCustCredit + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

			UPDATE
				MCustCredit
			SET
				GTotReturnAmnt				=	GTotReturnAmnt + @w_FAcrcvH_SalesAmnt
			,	GTotReturnTax				=	GTotReturnTax + @w_FAcrcvH_SalesTax
			,	TotReturnAmnt				=	TotReturnAmnt + @w_FAcrcvH_SalesAmnt + @w_FAcrcvH_SalesTax
			,	AcrcvBalAmnt				=	AcrcvBalAmnt - @w_FAcrcvH_SalesAmnt - @w_FAcrcvH_SalesTax
			,	LastReturnDt				=	@w_NowDt
			,	UpdateUserCd				=	@UserCd
			,	UpdateWinDate				=	GETDATE()
			,	UpdateCount					=	dbo.FW_FNC_NextNo( UpdateCount )
			,	UpdateWinMod				=	@UpdateJobMod
			WHERE
				CustNo = @CustNo
			AND
				DelFlg = @ct_OffFlg

			-- 更新したお客様債権台帳件数
			SET	@w_MCustCreditUpdateCnt		+=	@@ROWCOUNT

			-- 3.2.5 返品伝票へダー登録
			-- エラーメッセージ編集
			SET	@ErrMsg						=	@ct_TableName_FReturnH + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

			-- ポイント履歴番号を取得する
			EXECUTE STP_SYS_GetKey @ct_AddCnt, @ct_ReturnNoSeqKey, @w_ReturnNo OUTPUT, @ErrCode OUTPUT, @ErrMsg OUTPUT

			IF @ErrCode <> @ct_Success_Success
			BEGIN
				SET @Success				=	@ct_RtnCd_ERR
				SET @w_MsgCd				=	@ct_ErrCd_SysSeq
				SET @ErrMsg					=	@ct_ReturnNoSeqKey
				EXECUTE FW_STP_GetApMessage @w_MsgCd, @ErrMsg, @w_ApplicationMessage OUTPUT
				-- 処理終了するためにエラー発生
				RAISERROR( @w_ApplicationMessage, @ct_BusinessException, @ct_RaisErrorState )
			END

			-- [返品伝票ヘダー]へ登録する
			INSERT INTO FReturnH
			(
				ReturnNo
			,	CustNo
			,	ReturnFixStat
			,	ReturnFixDt
			,	RealProcDate
			,	ReturnLugExteriorKbn
			,	ReturnEnclosExistFlg
			,	ReturnEnclosContMemo
			,	ReturnFixUserCd
			,	ReturnLugRcvDt
			,	ReturnLugRcvTmZoneKbn
			,	DlvCorpCd
			,	DlvCorpName
			,	ReturnMemo
			,	ReturnShipping
			,	ReturnShippingTax
			,	ReturnLugDestKbn
			,	RegisterUserCd
			,	RegisterDate
			,	UpdateUserCd
			,	UpdateWinDate
			,	UpdateJobDate
			,	UpdateCount
			,	UpdateWinMod
			,	UpdateJobMod
			,	DelFlg
			,	ReturnTariff
			)
			VALUES
			(
				@w_ReturnNo
			,	@CustNo
			,	@ct_ReturnFixStat_99
			,	@w_NowDt
			,	@ct_UnSetDtTm
			,	@ct_NullChar
			,	@ct_OffFlg
			,	@ct_NullChar
			,	@ct_NullChar
			,	@ct_IntZero
			,	@ct_NullChar
			,	@ct_NullChar
			,	@ct_NullChar
			,	@ct_NullChar
			,	@ct_IntZero
			,	@ct_IntZero
			,	@ct_NullChar
			,	@UserCd
			,	GETDATE()
			,	@UserCd
			,	GETDATE()
			,	GETDATE()
			,	@ct_IntZero
			,	@UpdateJobMod
			,	@ct_NullChar
			,	@ct_OffFlg
			,	@ct_IntZero
			)

			-- 挿入した返品伝票ヘッダー件数
			SET	@w_FReturnHInsertCnt		+=	@@ROWCOUNT

			-- 3.2.6 返品伝票明細登録
			-- 例外用エラーメッセージ編集
			SET	@ErrMsg						=	@ct_CursorName_FReturnDData		+@ct_ErrMsg_Key_OdrNo + CONVERT( VARCHAR, @OdrNo )

			DECLARE c_FReturnDData CURSOR FAST_FORWARD FOR
				SELECT
					FOD.OdrDtlNo			AS	OdrDtlNo
				,	FOD.ItemKbn				AS	ItemKbn
				,	FOD.ItemCd				AS	ItemCd
				,	FOD.ItemLvlCd			AS	ItemLvlCd
				,	FOD.ItemNum				AS	ItemNum
				,	FOD.ItemPrice			AS	ItemPrice
				,	FOD.ItemPriceTax		AS	ItemPriceTax
				,	FOD.TaxKbn				AS	TaxKbn
				,	FOD.TaxRateKbn			AS	TaxRateKbn
				,	FOD.OccurPointNum		AS	OccurPointNum
				,	FOD.UsePointNum			AS	UsePointNum
				FROM
					FOdrD FOD WITH(NOLOCK)
				INNER JOIN
					FodrH FOH WITH(NOLOCK)
				ON
					FOD.OdrNo = FOH.OdrNo
				AND
					FOH.DelFlg = @ct_OffFlg
				WHERE
					FOD.OdrNo = @OdrNo
				AND
					FOD.DelFlg = @ct_OffFlg
				ORDER BY
					FOD.OdrDtlNo
				OPTION (MAXDOP 1)

			---------------------------------
			-- 注文伝票明細カーソルオープン
			---------------------------------
			--カーソルOPEN
			OPEN c_FReturnDData

			---------------------------------
			-- 注文伝票明細カーソルフェッチ
			---------------------------------
			-- 例外用エラーメッセージ編集
			SET	@ErrMsg						=	@ct_CursorName_FReturnDData	+ @ct_ErrMsg_Key_OdrNo + CONVERT( VARCHAR, @OdrNo )

			FETCH NEXT FROM c_FReturnDData INTO
				@w_FOdrD_OdrDtlNo													-- <注文伝票明細>.[注文明細番号]
			,	@w_FOdrD_ItemKbn													-- <注文伝票明細>.[商品区分]
			,	@w_FOdrD_ItemCd														-- <注文伝票明細>.[商品コード]
			,	@w_FOdrD_ItemLvlCd													-- <注文伝票明細>.[商品レベルコード]
			,	@w_FOdrD_ItemNum													-- <注文伝票明細>.[商品数]
			,	@w_FOdrD_ItemPrice													-- <注文伝票明細>.[商品単価]
			,	@w_FOdrD_ItemPriceTax												-- <注文伝票明細>.[商品単価消費税]
			,	@w_FOdrD_TaxKbn														-- <注文伝票明細>.[課税区分]
			,	@w_FOdrD_TaxRateKbn													-- <注文伝票明細>.[消費税率区分]
			,	@w_FOdrD_OccurPointNum												-- <注文伝票明細>.[発生ポイント数]
			,	@w_FOdrD_UsePointNum												-- <注文伝票明細>.[利用ポイント数]

			---------------------------------------------------------
			-- カーソルで取得した行が終端に達するまで処理を継続する
			---------------------------------------------------------
			WHILE ( @@FETCH_STATUS = @ct_IntZero )
			BEGIN
				-- エラーメッセージ編集
				SET	@ErrMsg					=	@ct_TableName_FReturnD + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

				-- [返品伝票明細]へ登録する
				INSERT	INTO	FReturnD
				(
					ReturnNo
				,	ReturnDtlNo
				,	DirectReturnFlg
				,	ItemUnOpenFlg
				,	ShipClsKbn
				,	ItemKbn
				,	ItemCd
				,	ItemLvlCd
				,	ProdCd
				,	ItemLotNo
				,	ReturnNum
				,	ReturnItemPrice
				,	ReturnTax
				,	TaxKbn
				,	TaxRateKbn
				,	UseVol
				,	ForUseAmnt
				,	RevivalPointNum
				,	InvalidPointNum
				,	RegisterUserCd
				,	RegisterDate
				,	UpdateUserCd
				,	UpdateWinDate
				,	UpdateJobDate
				,	UpdateCount
				,	UpdateWinMod
				,	UpdateJobMod
				,	DelFlg
				)
				VALUES
				(
					@w_ReturnNo
				,	@w_FOdrD_OdrDtlNo
				,	@ct_IntZero
				,	@ct_IntZero
				,	@ct_NullChar
				,	@w_FOdrD_ItemKbn
				,	@w_FOdrD_ItemCd
				,	@w_FOdrD_ItemLvlCd
				,	@ct_NullChar
				,	@ct_NullChar
				,	@w_FOdrD_ItemNum
				,	@w_FOdrD_ItemPrice
				,	@w_FOdrD_ItemPriceTax
				,	@w_FOdrD_TaxKbn
				,	@w_FOdrD_TaxRateKbn
				,	@ct_IntZero
				,	@ct_IntZero
				,	@w_FOdrD_OccurPointNum
				,	@w_FOdrD_UsePointNum
				,	@UserCd
				,	GETDATE()
				,	@UserCd
				,	GETDATE()
				,	GETDATE()
				,	@ct_IntZero
				,	@UpdateJobMod
				,	@ct_NullChar
				,	@ct_OffFlg
				)

				-- 挿入した返品伝票詳細件数
				SET	@w_FReturnDInsertCnt	+=	@@ROWCOUNT

				---------------------------------
				-- 注文伝票明細カーソルフェッチ
				---------------------------------
				-- 例外用エラーメッセージ編集
				SET @ErrMsg					=	@ct_CursorName_FReturnDData		+ @ct_ErrMsg_Key_OdrNo + CONVERT( VARCHAR, @OdrNo )

				FETCH NEXT FROM c_FReturnDData INTO
					@w_FOdrD_OdrDtlNo												-- <注文伝票明細>.[注文明細番号]
				,	@w_FOdrD_ItemKbn												-- <注文伝票明細>.[商品区分]
				,	@w_FOdrD_ItemCd													-- <注文伝票明細>.[商品コード]
				,	@w_FOdrD_ItemLvlCd												-- <注文伝票明細>.[商品レベルコード]
				,	@w_FOdrD_ItemNum												-- <注文伝票明細>.[商品数]
				,	@w_FOdrD_ItemPrice												-- <注文伝票明細>.[商品単価]
				,	@w_FOdrD_ItemPriceTax											-- <注文伝票明細>.[商品単価消費税]
				,	@w_FOdrD_TaxKbn													-- <注文伝票明細>.[課税区分]
				,	@w_FOdrD_TaxRateKbn												-- <注文伝票明細>.[消費税率区分]
				,	@w_FOdrD_OccurPointNum											-- <注文伝票明細>.[発生ポイント数]
				,	@w_FOdrD_UsePointNum											-- <注文伝票明細>.[利用ポイント数]
			END

			-- カーソル解放処理
			EXECUTE FW_STP_DisposeCursor NULL, 'c_FReturnDData', @UpdateJobMod, @UserCd, @Success OUTPUT

			-- 3.2.7 抹消返品履歴登録
			-- 3.2.7.1 売掛伝票へダーから以下の項目を取得する
			SELECT
				@w_FAcrcvH_TotReturnAmnt	=	TotReturnAmnt
			,	@w_FAcrcvH_ReturnAmnt		=	ReturnAmnt
			,	@w_FAcrcvH_ReturnTax		=	ReturnTax
			,	@w_FAcrcvH_ReturnShipping	=	ReturnShipping
			,	@w_FAcrcvH_ReturnShippingTax=	ReturnShippingTax
			,	@w_FAcrcvH_ReturnFee		=	ReturnFee
			,	@w_FAcrcvH_SalesFeeTax		=	SalesFeeTax
			,	@w_FAcrcvH_SalesSumUpDt		=	SalesSumUpDt
			FROM
				FAcrcvH WITH (NOLOCK)
			WHERE
				OdrNo = @OdrNo
			AND
				DelFlg = @ct_OffFlg
			OPTION (MAXDOP 1)

			-- エラーメッセージ編集
			SET	@ErrMsg						=	@ct_TableName_HEraseReturn + @ct_ErrMsg_Key_CustNo + CONVERT( VARCHAR, @CustNo )

			INSERT	INTO	HEraseReturn
			(
				OdrNo
			,	ReturnNo
			,	CustNo
			,	NewOdrNo
			,	SumUpDt
			,	SalesEraseKbn
			,	TotEraseReturnAmnt
			,	EraseReturnAmnt
			,	EraseReturnTax
			,	EraseReturnShipping
			,	EraseReturnShippingTax
			,	EraseReturnFee
			,	EraseReturnFeeTax
			,	RegisterUserCd
			,	RegisterDate
			,	UpdateUserCd
			,	UpdateWinDate
			,	UpdateJobDate
			,	UpdateCount
			,	UpdateWinMod
			,	UpdateJobMod
			,	DelFlg
			,	EraseReturnTariff
			)
			VALUES
			(
				@OdrNo
			,	@w_ReturnNo
			,	@CustNo
			,	@ct_BigIntZero
			,	@w_FAcrcvH_SalesSumUpDt
			,	@ct_SalesEraseKbn_2
			,	@w_FAcrcvH_TotReturnAmnt
			,	@w_FAcrcvH_ReturnAmnt
			,	@w_FAcrcvH_ReturnTax
			,	@w_FAcrcvH_ReturnShipping
			,	@w_FAcrcvH_ReturnShippingTax
			,	@w_FAcrcvH_ReturnFee
			,	@w_FAcrcvH_SalesFeeTax
			,	@UserCd
			,	GetDate()
			,	@UserCd
			,	GetDate()
			,	GetDate()
			,	@ct_IntZero
			,	@UpdateJobMod
			,	@ct_NullChar
			,	@ct_OffFlg
			,	@ct_DecimalZero
			)

			-- 挿入した抹消返品履歴件数
			SET	@w_HEraseReturnInsertCnt		+=	@@ROWCOUNT
		END

		--メッセージ初期化
		SET	@ErrMsg								=	@ct_NullChar

	END TRY

	BEGIN CATCH
		-- プロシージャの成否設定
		SET @Success							=	@ct_Success_Error
		SET @ErrCode							=	@@ERROR
	END CATCH
	BEGIN
		--########################################################################
		--## Finally															##
		--########################################################################
		--------------------------------------------------------------------------
		-- 更新した注文伝票ヘッダー件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_FOdrH + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_FodrHUpdateCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		--------------------------------------------------------------------------
		-- 更新した注文伝票詳細件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_FOdrD + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_FodrDUpdateCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		--------------------------------------------------------------------------
		-- 更新した統一発票伝票ヘッダー件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_FGuiNoH + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_FGuiNoHUpdateCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		--------------------------------------------------------------------------
		-- 更新した発票注意伝票件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_FShipAtt + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_FShipAttUpdateCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		--------------------------------------------------------------------------
		-- 更新した施策獲得履歴件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_HCampgnGet + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_HCampgnGetUpdateCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		--------------------------------------------------------------------------
		-- 更新した施策獲得履歴件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_MCustBal + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_MCustBalUpdateCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		--------------------------------------------------------------------------
		-- 更新した紹介者台帳がある[被紹介者サンプル請求番号] = [注文コード]の件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_MIntroCust + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_MIntroCustReqNoCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		--------------------------------------------------------------------------
		-- 更新した紹介者台帳がある[被紹介者初回注文番号] = [注文コード]の件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_MIntroCust + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_MIntroCustFirstOdrNoCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		--------------------------------------------------------------------------
		-- 更新した紹介者台帳がある[紹介者特典注文番号] = [注文コード]の件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_MIntroCust + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_MIntroCustFavorOdrNoCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		-------------------------------------------------------------------------
		-- 挿入した発生ポイントがあるポイント履歴件数
		--------------------------------------------------------------------------
		SET @w_MessageList  = @ct_LeftParenthes + @ct_TableName_HPoint + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_HPointOccurPointNumInsertCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_MSG, @ct_MsgCd_INS, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		-------------------------------------------------------------------------
		-- 挿入した使用ポイントがあるポイント履歴件数
		--------------------------------------------------------------------------
		SET @w_MessageList  = @ct_LeftParenthes + @ct_TableName_HPoint + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_HPointUsePointNumInsertCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_MSG, @ct_MsgCd_INS, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		-------------------------------------------------------------------------
		-- 挿入したヘッダー部に実績更新履歴の件数
		--------------------------------------------------------------------------
		SET @w_MessageList  = @ct_LeftParenthes + @ct_TableName_HPoint + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_HActualHUpdInsertCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_MSG, @ct_MsgCd_INS, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		-------------------------------------------------------------------------
		-- 挿入した明細部に実績更新履歴の件数
		--------------------------------------------------------------------------
		SET @w_MessageList  = @ct_LeftParenthes + @ct_TableName_HPoint + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_HActualDpdInsertCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_MSG, @ct_MsgCd_INS, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		-------------------------------------------------------------------------
		-- 更新した売掛伝票ヘッダー件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_FAcrcvH + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_FAcrcvHUpdateCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		-------------------------------------------------------------------------
		-- 更新した売掛伝票詳細件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_FAcrcvD + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_FAcrcvDUpdateCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		-------------------------------------------------------------------------
		-- 更新した支払期限による売掛伝票詳細件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_FAcrcvPayTerm + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_FAcrcvPayTermUpdateCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		-------------------------------------------------------------------------
		-- 更新したお客様債権台帳件数
		--------------------------------------------------------------------------
		SELECT @w_MessageList = @ct_LeftParenthes + @ct_TableName_MCustCredit + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_MCustCreditUpdateCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_UPD, @ct_MsgCd_UPD, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		-------------------------------------------------------------------------
		-- 挿入した返品伝票ヘッダー件数
		--------------------------------------------------------------------------
		SET @w_MessageList  = @ct_LeftParenthes + @ct_TableName_FReturnH + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_FReturnHInsertCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_MSG, @ct_MsgCd_INS, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		-------------------------------------------------------------------------
		-- 挿入した返品伝票詳細件数
		--------------------------------------------------------------------------
		SET @w_MessageList  = @ct_LeftParenthes + @ct_TableName_FReturnD + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_FReturnDInsertCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_MSG, @ct_MsgCd_INS, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		-------------------------------------------------------------------------
		-- 挿入した抹消返品履歴件数
		--------------------------------------------------------------------------
		SET @w_MessageList  = @ct_LeftParenthes + @ct_TableName_HEraseReturn + @ct_RightParenthes + @ct_TAB + CONVERT( VARCHAR, @w_HEraseReturnInsertCnt )
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_MSG, @ct_MsgCd_INS, @w_MessageList, @UpdateJobMod, @ct_ProcedureName, @UserCd

		-- ジョブ実行終了ログ出力
		EXECUTE FW_STP_WriteLog @ct_MsgKbn_EOT, @ct_MsgCd_EOT, @ct_ProcedureName, @UpdateJobMod, @ct_ProcedureName, @UserCd 
	END

END